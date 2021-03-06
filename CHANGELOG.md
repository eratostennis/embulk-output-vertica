# 0.7.4 (2016/05/07)

Fixes:

* Add missing "require 'timeout'"

# 0.7.3 (2016/03/27)

Enhancements:

* Add write_timeout option
* Add finish_timeout option
* Add dequeuen_timeout option

Changes:

* Transfer repository from eratostennis to sonots

# 0.7.2 (2016/02/10)

Fixes:

* Fix to get stuck if no input is comming
* Fix to get stcuk if one record is longer thant IO pipe maximum size (64k bytes for Linux, and Mac OSX)

# 0.7.1 (2016/01/30)

Enhancements:

* Create table with INCLUDING PROJECTIONS on mode `REPLACE`

# 0.7.0 (2016/01/29)

Breaking Changes:

* rename mode `REPLACE` to `DROP_INSERT`

Enhancements:

* Add mode `REPLACE` which copies rows to an intermediate table first. If all those tasks run correctly, swaps the target table and the intermediate table, and drops the old target table

# 0.6.2 (2016/01/28)

Enhancements:

* Use `CREATE TABLE LIKE` statement to create a temp table to copy nullable or other parameters

# 0.6.1 (2016/01/26)

Fixes:

* Remove debug code...

# 0.6.0 (2016/01/26)

Changes:

* Add `/*+ direct */` hint to insert select if copy_mode == DIRECT

# 0.5.9 (2016/01/26)

Enhancements:

* log speed (rows/sec) of progress

Trivial changes:

* Use ::Jvertica.quote to quote resource_pool
* change log_level of push / pop finish
* change log_level of select result from debug to trace

# 0.5.8 (2016/01/24)

Enhancements:

* Add resource_pool option

# 0.5.7 (2016/01/22)

Enhancements:

* Add json_payload option to avoid construction of JSON in this jruby plugin for performance improvement

# 0.5.6 (2016/01/22)

Enhancements:

* Perform to_json in embulk threads. This achieves better performance when pool < num_threads

# 0.5.5 (2016/01/22)

Changes:

* Show input_num_rows info log to see progress

# 0.5.4 (2016/01/21)

Enhancements:

* Log rejected record

# 0.5.3 (2016/01/09)

Enhancements:

* Add more trace logs

# 0.5.2 (2016/01/09)

Fixes:

* Add nil check for timestamp converter
* Fix error handling of output thread

# 0.5.1 (2015/12/04)

Fixes:

* Need mutex.synchroize for OutputThreadPool#enqueue because it is called by #add which is ran by multiple threads

# 0.5.0 (2015/12/04)

Changes:

* Use thread pool instead of connection pool #13

# 0.4.1 (2015/12/04)

Fixes:

* Create internal vertica projection beforehand to avoid S Lock error 

# 0.4.0 (2015/11/24)

Enhancements:

* Support connection pool

# 0.3.1 (2015/11/20)

Fixes:

* Fix timezone support for the case that column_options is not specified (use default_timezone)

# 0.3.0 (2015/11/17)

Changes:

* Change log level of COMMIT statement from info to debug

# 0.2.9 (2015/11/17)

Changes:

* Change log level of COPY statement from info to debug

# 0.2.8 (2015/11/06)

Enhancements:

* Get sql schema from the existing target table to create internal temporary tables to avoid schema conflicts

# 0.2.7 (2015/11/06)

Skipped

# 0.2.6 (2015/11/06)

Fixes:

* Fix not to raise ConfigError for upcase mode, and copy_mode

# 0.2.5 (2015/10/26)

Changes:

* Output task_reports log as json

# 0.2.4 (2015/10/23)

Changes:

* Rename `username` to `user` to be compatible with ruby vertica gem and jruby jvertica gem
  * still, support `username` for backward compatibility

# 0.2.3 (2015/09/16)

Changes:

* Commit all pages at burst (in each task)

Enhancements:

* Return task_reports

# 0.2.2 (2015/07/24)

Changes:

* Change some log level from debug to info

# 0.2.1 (2015/07/24)

Fixes:

* Fix to support timezone 'UTC'

# 0.2.0 (2015/07/24)

Enhancements:

* Add `default_timezone` option

# 0.1.9 (2015/07/24)

Enhancements:

* Support `timezone` for string converter

# 0.1.8 (2015/07/24)

Enhancements:

* Support `value_type`, `timezone_format`, `timezone` option for column_options

# 0.1.7 (2015/07/24)

Enhancements:

* Add `reject_on_materialized_type_error` option

# 0.1.6 (2015/07/23)

Enhancements:

* Enhancement of debug log

# 0.1.5 (2015/07/23)

Fixes:

* Use PARSER fjsonparser() instead of DELIMITER ',', otherwise escape is too difficult to do

# 0.1.4 (2015/07/10)

Fixes:

* Just fix gemspec

# 0.1.3 (2015/07/05)

Enhancements:

* Escape schama, table names
* Add `abort_on_error` option

# 0.1.2 (2015/06/26)

Enhancements:

* Add `column_options` option

# 0.1.1 (2015/06/25)

Enhancements:

* Add `copy_mode` option
* Use `jvertica` gem instead of `vertica` gem

# 0.1.0

first version

