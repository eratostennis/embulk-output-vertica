require 'zlib'

module Embulk
  module Output
    class Vertica < OutputPlugin
      class OutputThreadPool
        def initialize(task, schema, size)
          @task = task
          @size = size
          @schema = schema
          @converters = ValueConverterFactory.create_converters(schema, task['default_timezone'], task['column_options'])
          @output_threads = size.times.map { OutputThread.new(task) }
          @current_index = 0
        end

        def enqueue(page)
          json_page = []
          page.each do |record|
            json_page << to_json(record)
          end
          @mutex.synchronize do
            @output_threads[@current_index].enqueue(json_page)
            @current_index = (@current_index + 1) % @size
          end
        end

        def start
          @mutex = Mutex.new
          @size.times.map {|i| @output_threads[i].start }
        end

        def commit
          task_reports = @size.times.map {|i| @output_threads[i].commit }
        end

        def to_json(record)
          if @task['json_payload']
            record.first
          else
            Hash[*(@schema.names.zip(record).map do |column_name, value|
              [column_name, @converters[column_name].call(value)]
            end.flatten!(1))].to_json
          end
        end
      end

      class OutputThread
        def initialize(task)
          @task = task
          @queue = SizedQueue.new(1)
          @num_input_rows = 0
          @num_output_rows = 0
          @num_rejected_rows = 0
          @outer_thread = Thread.current
          @thread_active = false
          @progress_log_timer = Time.now

          case task['compress']
          when 'GZIP'
            @write_proc = self.method(:write_gzip)
          else
            @write_proc = self.method(:write_uncompressed)
          end
        end

        def enqueue(json_page)
          if @thread_active and @thread.alive?
            Embulk.logger.trace { "embulk-output-vertica: enqueue" }
            @queue.push(json_page)
          else
            Embulk.logger.info { "embulk-output-vertica: thread is dead, but still trying to enqueue" }
            raise RuntimeError, "embulk-output-vertica: thread is died, but still trying to enqueue"
          end
        end

        def write_gzip(io, page, &block)
          buf = Zlib::Deflate.new
          write_buf(buf, page, &block)
          io << buf.finish
        end

        def write_uncompressed(io, page, &block)
          buf = ''
          write_buf(buf, page, &block)
          io << buf
        end

        def write_buf(buf, json_page, &block)
          json_page.each do |record|
            yield(record) if block_given?
            Embulk.logger.trace { "embulk-output-vertica: record #{record}" }
            buf << record << "\n"
            @num_input_rows += 1
          end
          now = Time.now
          if @progress_log_timer < now - 10 # once in 10 seconds
            @progress_log_timer = now
            Embulk.logger.info { "embulk-output-vertica: num_input_rows #{@num_input_rows}" }
          end
        end

        def run
          Embulk.logger.debug { "embulk-output-vertica: thread started" }
          Vertica.connect(@task) do |jv|
            begin
              last_record = nil
              num_output_rows, rejects = copy(jv, copy_sql) do |stdin|
                while json_page = @queue.pop
                  if json_page == 'finish'
                    Embulk.logger.trace { "embulk-output-vertica: popped finish" }
                    break
                  end
                  Embulk.logger.trace { "embulk-output-vertica: dequeued" }

                  @write_proc.call(stdin, json_page) do |record|
                    last_record = record
                  end
                end
              end
              Embulk.logger.debug { "embulk-output-vertica: thread finished" }
              num_rejected_rows = rejects.size
              @num_output_rows += num_output_rows
              @num_rejected_rows += num_rejected_rows
              Embulk.logger.info { "embulk-output-vertica: COMMIT!" }
              jv.commit
              Embulk.logger.debug { "embulk-output-vertica: COMMITTED!" }
            rescue java.sql.SQLDataException => e
              if @task['reject_on_materialized_type_error'] and e.message =~ /Rejected by user-defined parser/
                Embulk.logger.warn "embulk-output-vertica: ROLLBACK! some of column types and values types do not fit #{last_record}"
              else
                Embulk.logger.warn "embulk-output-vertica: ROLLBACK!"
              end
              Embulk.logger.info { "embulk-output-vertica: last_record: #{last_record}" }
              jv.rollback
              raise e # die transaction
            rescue => e
              Embulk.logger.warn "embulk-output-vertica: ROLLBACK!"
              jv.rollback
              raise e
            end
          end
        rescue => e
          @thread_active = false # not to be enqueued any more
          while @queue.size > 0
            @queue.pop # dequeue all because some might be still trying @queue.push and get blocked, need to release
          end
          @outer_thread.raise e.class.new("#{e.message}\n  #{e.backtrace.join("\n  ")}")
        end

        def start
          @thread = Thread.new(&method(:run))
          @thread_active = true
        end

        def commit
          @thread_active = false
          if @thread.alive?
            @queue.push('finish')
            Embulk.logger.trace { "embulk-output-vertica: pushed finish" }
            Thread.pass
            @thread.join
          else
            raise RuntimeError, "embulk-output-vertica: thread died accidently"
          end

          task_report = {
            'num_input_rows' => @num_input_rows,
            'num_output_rows' => @num_output_rows,
            'num_rejected_rows' => @num_rejected_rows,
          }
        end

        # private

        def copy(conn, sql, &block)
          Embulk.logger.debug "embulk-output-vertica: #{sql}"
          results, rejects = conn.copy(sql, &block)
        end

        def copy_sql
          @copy_sql ||= "COPY #{quoted_schema}.#{quoted_temp_table} FROM STDIN#{compress}#{fjsonparser}#{copy_mode}#{abort_on_error} NO COMMIT"
        end

        def quoted_schema
          ::Jvertica.quote_identifier(@task['schema'])
        end

        def quoted_table
          ::Jvertica.quote_identifier(@task['table'])
        end

        def quoted_temp_table
          ::Jvertica.quote_identifier(@task['temp_table'])
        end

        def compress
          " #{@task['compress']}"
        end

        def copy_mode
          " #{@task['copy_mode']}"
        end

        def abort_on_error
          @task['abort_on_error'] ? ' ABORT ON ERROR' : ''
        end

        def fjsonparser
          " PARSER fjsonparser(#{reject_on_materialized_type_error})"
        end

        def reject_on_materialized_type_error
          @task['reject_on_materialized_type_error'] ? 'reject_on_materialized_type_error=true' : ''
        end
      end
    end
  end
end