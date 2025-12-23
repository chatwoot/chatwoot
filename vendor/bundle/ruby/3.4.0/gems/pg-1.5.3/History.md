## v1.5.3 [2023-04-28] Lars Kanis <lars@greiz-reinsdorf.de>

- Fix possible segfault when creating a new PG::Result with type map. [#530](https://github.com/ged/ruby-pg/pull/530)
- Add category to deprecation warnings of Coder.new, so that they are suppressed for most users. [#528](https://github.com/ged/ruby-pg/pull/528)


## v1.5.2 [2023-04-26] Lars Kanis <lars@greiz-reinsdorf.de>

- Fix regression in copy_data regarding binary format when using no coder. [#527](https://github.com/ged/ruby-pg/pull/527)


## v1.5.1 [2023-04-24] Lars Kanis <lars@greiz-reinsdorf.de>

- Don't overwrite flags of timestamp coders. [#524](https://github.com/ged/ruby-pg/pull/524)
  Fixes a regression in rails: https://github.com/rails/rails/issues/48049


## v1.5.0 [2023-04-24] Lars Kanis <lars@greiz-reinsdorf.de>

Enhancements:

- Better support for binary format:
    - Extend PG::Connection#copy_data to better support binary transfers [#511](https://github.com/ged/ruby-pg/pull/511)
    - Add binary COPY encoder and decoder:
        * PG::BinaryEncoder::CopyRow
        * PG::BinaryDecoder::CopyRow
    - Add binary timestamp encoders:
        * PG::BinaryEncoder::TimestampUtc
        * PG::BinaryEncoder::TimestampLocal
        * PG::BinaryEncoder::Timestamp
    - Add PG::BinaryEncoder::Float4 and Float8
    - Add binary date type: [#515](https://github.com/ged/ruby-pg/pull/515)
        * PG::BinaryEncoder::Date
        * PG::BinaryDecoder::Date
    - Add PG::Result#binary_tuples [#511](https://github.com/ged/ruby-pg/pull/511)
      It is useful for COPY and not deprecated in that context.
    - Add PG::TextEncoder::Bytea to BasicTypeRegistry [#506](https://github.com/ged/ruby-pg/pull/506)
- Ractor support: [#519](https://github.com/ged/ruby-pg/pull/519)
    - Pg is now fully compatible with Ractor introduced in Ruby-3.0 and doesn't use any global mutable state.
    - All type en/decoders and type maps are shareable between ractors if they are made frozen by `Ractor.make_shareable`.
    - Also frozen PG::Result and PG::Tuple objects can be shared.
    - All frozen objects (except PG::Connection) can still be used to do communication with the PostgreSQL server or to read retrieved data.
    - PG::Connection is not shareable and must be created within each Ractor to establish a dedicated connection.
- Use keyword arguments instead of hashes for Coder initialization and #to_h. [#511](https://github.com/ged/ruby-pg/pull/511)
- Add PG::Result.res_status as a class method and extend Result#res_status to return the status of self. [#508](https://github.com/ged/ruby-pg/pull/508)
- Reduce the number of files loaded at `require 'pg'` by using autoload. [#513](https://github.com/ged/ruby-pg/pull/513)
  Previously stdlib libraries `date`, `json`, `ipaddr` and `bigdecimal` were static dependencies, but now only `socket` is mandatory.
- Improve garbage collector performance by adding write barriers to all PG classes. [#518](https://github.com/ged/ruby-pg/pull/518)
  Now they can be promoted to the old generation, which means they only get marked on major GC.
- New method PG::Connection#check_socket to check the socket state. [#521](https://github.com/ged/ruby-pg/pull/521)
- Mark many internal constants as private. [#522](https://github.com/ged/ruby-pg/pull/522)
- Update Windows fat binary gem to OpenSSL-3.1.0.

Bugfixes:

- Move nfields-check of stream-methods after result status check [#507](https://github.com/ged/ruby-pg/pull/507)
  This ensures that the nfield-check doesn't hide errors like statement timeout.

Removed:

- Remove deprecated PG::BasicTypeRegistry.register_type and co. [Part of #519](https://github.com/ged/ruby-pg/commit/2919ee1a0c6b216e18e1d06c95c2616ef69d2f97)
- Add deprecation warning about PG::Coder initialization per Hash argument. [#514](https://github.com/ged/ruby-pg/pull/514)
  It is recommended to use keyword arguments instead.
- The internal encoding cache was removed. [#516](https://github.com/ged/ruby-pg/pull/516)
  It shouldn't have a practical performance impact.

Repository:

- `rake test` tries to find PostgreSQL server commands by pg_config [#503](https://github.com/ged/ruby-pg/pull/503)
  So there's no need to set the PATH manuelly any longer.


## v1.4.6 [2023-02-26] Lars Kanis <lars@greiz-reinsdorf.de>

- Add japanese README file. [#502](https://github.com/ged/ruby-pg/pull/502)
- Improve `discard_results` to not block under memory pressure. [#500](https://github.com/ged/ruby-pg/pull/500)
- Use a dedicated error class `PG::LostCopyState` for errors due to another query within `copy_data` and mention that it's probably due to another query.
  Previously the "no COPY in progress" `PG::Error` was less specific. [#499](https://github.com/ged/ruby-pg/pull/499)
- Make sure an error in `put_copy_end` of `copy_data`  doesn't lose the original exception.
- Disable nonblocking mode while large object calls. [#498](https://github.com/ged/ruby-pg/pull/498)
  Since pg-1.3.0 libpq's "lo_*" calls failed when a bigger amount of data was transferred.
  This specifically forced the `active_storage-postgresql` gem to use pg-1.2.3.
- Add rdoc options to gemspec, so that "gem install" generates complete offline documentation.
- Add binary Windows gems for Ruby 3.2.
- Update Windows fat binary gem to PostgreSQL-15.2 and OpenSSL-3.0.8.


## v1.4.5 [2022-11-17] Lars Kanis <lars@greiz-reinsdorf.de>

- Return the libpq default port when blank in conninfo. [#492](https://github.com/ged/ruby-pg/pull/492)
- Add PG::DEF_PGPORT constant and use it in specs. [#492](https://github.com/ged/ruby-pg/pull/492)
- Fix name resolution when empty or `nil` port is given.
- Update error codes to PostgreSQL-15.
- Update Windows fat binary gem to PostgreSQL-15.1 AND OpenSSL-1.1.1s.


## v1.4.4 [2022-10-11] Lars Kanis <lars@greiz-reinsdorf.de>

- Revert to let libpq do the host iteration while connecting. [#485](https://github.com/ged/ruby-pg/pull/485)
  Ensure that parameter `connect_timeout` is still respected.
- Handle multiple hosts in the connection string, where only one host has writable session. [#476](https://github.com/ged/ruby-pg/pull/476)
- Add some useful information to PG::Connection#inspect. [#487](https://github.com/ged/ruby-pg/pull/487)
- Support new pgresult_stream_any API in sequel_pg-1.17.0. [#481](https://github.com/ged/ruby-pg/pull/481)
- Update Windows fat binary gem to PostgreSQL-14.5.


## v1.4.3 [2022-08-09] Lars Kanis <lars@greiz-reinsdorf.de>

- Avoid memory bloat possible in put_copy_data in pg-1.4.0 to 1.4.2. [#473](https://github.com/ged/ruby-pg/pull/473)
- Use Encoding::BINARY for JOHAB, removing some useless code. [#472](https://github.com/ged/ruby-pg/pull/472)


## v1.4.2 [2022-07-27] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Properly handle empty host parameter when connecting. [#471](https://github.com/ged/ruby-pg/pull/471)
- Update Windows fat binary gem to OpenSSL-1.1.1q.


## v1.4.1 [2022-06-24] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Fix another ruby-2.7 keyword warning. [#465](https://github.com/ged/ruby-pg/pull/465)
- Allow PG::Error to be created without arguments. [#466](https://github.com/ged/ruby-pg/pull/466)


## v1.4.0 [2022-06-20] Lars Kanis <lars@greiz-reinsdorf.de>

Added:

- Add PG::Connection#hostaddr, present since PostgreSQL-12. [#453](https://github.com/ged/ruby-pg/pull/453)
- Add PG::Connection.conninfo_parse to wrap PQconninfoParse. [#453](https://github.com/ged/ruby-pg/pull/453)

Bugfixes:

- Try IPv6 and IPv4 addresses, if DNS resolves to both. [#452](https://github.com/ged/ruby-pg/pull/452)
- Re-add block-call semantics to PG::Connection.new accidently removed in pg-1.3.0. [#454](https://github.com/ged/ruby-pg/pull/454)
- Handle client error after all data consumed in #copy_data for output. [#455](https://github.com/ged/ruby-pg/pull/455)
- Avoid spurious keyword argument warning on Ruby 2.7. [#456](https://github.com/ged/ruby-pg/pull/456)
- Change connection setup to respect connect_timeout parameter. [#459](https://github.com/ged/ruby-pg/pull/459)
- Fix indefinite hang in case of connection error on Windows [#458](https://github.com/ged/ruby-pg/pull/458)
- Set connection attribute of PG::Error in various places where it was missing. [#461](https://github.com/ged/ruby-pg/pull/461)
- Fix transaction leak on early break/return. [#463](https://github.com/ged/ruby-pg/pull/463)
- Update Windows fat binary gem to OpenSSL-1.1.1o and PostgreSQL-14.4.

Enhancements:

- Don't flush at each put_copy_data call, but flush at get_result. [#462](https://github.com/ged/ruby-pg/pull/462)


## v1.3.5 [2022-03-31] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Handle PGRES_COMMAND_OK in pgresult_stream_any. [#447](https://github.com/ged/ruby-pg/pull/447)
  Fixes usage when trying to stream the result of a procedure call that returns no results.

Enhancements:

- Rename BasicTypeRegistry#define_default_types to #register_default_types to use a more consistent terminology.
  Keeping define_default_types for compatibility.
- BasicTypeRegistry: return self instead of objects by accident.
  This allows call chaining.
- Add some April fun. [#449](https://github.com/ged/ruby-pg/pull/449)

Documentation:
- Refine documentation of conn.socket_io and conn.connect_poll


## v1.3.4 [2022-03-10] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Don't leak IO in case of connection errors. [#439](https://github.com/ged/ruby-pg/pull/439)
  Previously it was kept open until the PG::Connection was garbage collected.
- Fix a performance regession in conn.get_result noticed in single row mode. [#442](https://github.com/ged/ruby-pg/pull/442)
- Fix occasional error Errno::EBADF (Bad file descriptor) while connecting. [#444](https://github.com/ged/ruby-pg/pull/444)
- Fix compatibility of res.stream_each* methods with Fiber.scheduler. [#446](https://github.com/ged/ruby-pg/pull/446)
- Remove FL_TEST and FL_SET, which are MRI-internal. [#437](https://github.com/ged/ruby-pg/pull/437)

Enhancements:

- Allow pgresult_stream_any to be used by sequel_pg. [#443](https://github.com/ged/ruby-pg/pull/443)


## v1.3.3 [2022-02-22] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Fix omission of the third digit of IPv4 addresses in connection URI. [#435](https://github.com/ged/ruby-pg/pull/435)
- Fix wrong permission of certs/larskanis-2022.pem in the pg-1.3.2.gem. [#432](https://github.com/ged/ruby-pg/pull/432)


## v1.3.2 [2022-02-14] Lars Kanis <lars@greiz-reinsdorf.de>

Bugfixes:

- Cancel only active query after failing transaction. [#430](https://github.com/ged/ruby-pg/pull/430)
  This avoids an incompatibility with pgbouncer since pg-1.3.0.
- Fix String objects with non-applied encoding when using COPY or record decoders. [#427](https://github.com/ged/ruby-pg/pull/427)
- Update Windows fat binary gem to PostgreSQL-14.2.

Enhancements:

- Improve extconf.rb checks to reduces the number of compiler calls.
- Add a check for PGRES_PIPELINE_SYNC, to make sure the library version and the header files are PostgreSQL-14+. [#429](https://github.com/ged/ruby-pg/pull/429)


## v1.3.1 [2022-02-01] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Fix wrong handling of socket writability on Windows introduced in [#417](https://github.com/ged/ruby-pg/pull/417).
  This caused starvation in conn.put_copy_data.
- Fix error in PG.version_string(true). [#419](https://github.com/ged/ruby-pg/pull/419)
- Fix a regression in pg 1.3.0 where Ruby 2.x busy-looping any fractional seconds for every wait. [#420](https://github.com/ged/ruby-pg/pull/420)

Enhancements:

- Raise an error when conn.copy_data is used in nonblocking mode.


## v1.3.0 [2022-01-20] Michael Granger <ged@FaerieMUD.org>

Install Enhancements:
- Print some install help if libpq wasn't found. [#396](https://github.com/ged/ruby-pg/pull/396)
  This should help to pick the necessary package without googling.
- Update Windows fat binary gem to OpenSSL-1.1.1m and PostgreSQL-14.1.
- Add binary Windows gems for Ruby 3.0 and 3.1.
- Make the library path of libpq available in ruby as PG::POSTGRESQL_LIB_PATH and add it to the search paths on Windows similar to +rpath+ on Unix systems. [#373](https://github.com/ged/ruby-pg/pull/373)
- Fall back to pkg-config if pg_config is not found. [#380](https://github.com/ged/ruby-pg/pull/380)
- Add option to extconf.rb to disable nogvl-wrapping of libpq functions.
  All methods (except PG::Connection.ping) are nonblocking now, so that GVL unlock is in theory no longer necessary.
  However it can have some advantage in concurrency, so that GVL unlock is still enabled by default.
  Use:
  - gem inst pg -- --disable-gvl-unlock

API Enhancements:
- Add full compatibility to Fiber.scheduler introduced in Ruby-3.0. [#397](https://github.com/ged/ruby-pg/pull/397)
  - Add async_connect and async_send methods and add specific specs for Fiber.scheduler [#342](https://github.com/ged/ruby-pg/pull/342)
  - Add async_get_result and async_get_last_result
  - Add async_get_copy_data
  - Implement async_put_copy_data/async_put_copy_end
  - Implement async_reset method using the nonblocking libpq API
  - Add async_set_client_encoding which is compatible to scheduler
  - Add async_cancel as a nonblocking version of conn#cancel
  - Add async_encrypt_password
  - Run Connection.ping in a second thread.
  - Make discard_results scheduler friendly
  - Do all socket waiting through the conn.socket_io object.
  - Avoid PG.connect blocking while address resolution by automatically providing the +hostaddr+ parameter and resolving in Ruby instead of libpq.
  - On Windows Fiber.scheduler support requires Ruby-3.1+.
    It is also only partly usable since may ruby IO methods are not yet scheduler aware on Windows.
- Add support for pipeline mode of PostgreSQL-14. [#401](https://github.com/ged/ruby-pg/pull/401)
- Allow specification of multiple hosts in PostgreSQL URI. [#387](https://github.com/ged/ruby-pg/pull/387)
- Add new method conn.backend_key - used to implement our own cancel method.

Type cast enhancements:
- Add PG::BasicTypeMapForQueries::BinaryData for encoding of bytea columns. [#348](https://github.com/ged/ruby-pg/pull/348)
- Reduce time to build coder maps and permit to reuse them for several type maps per PG::BasicTypeRegistry::CoderMapsBundle.new(conn) . [#376](https://github.com/ged/ruby-pg/pull/376)
- Make BasicTypeRegistry a class and use a global default instance of it.
  Now a local type registry can be instanciated and given to the type map, to avoid changing shared global states.
- Allow PG::BasicTypeMapForQueries to take a Proc as callback for undefined types.

Other Enhancements:
- Convert all PG classes implemented in C to TypedData objects. [#349](https://github.com/ged/ruby-pg/pull/349)
- Support ObjectSpace.memsize_of(obj) on all classes implemented in C. [#393](https://github.com/ged/ruby-pg/pull/393)
- Make all PG objects implemented in C memory moveable and therefore GC.compact friendly. [#349](https://github.com/ged/ruby-pg/pull/349)
- Update errorcodes and error classes to PostgreSQL-14.0.
- Add PG::CONNECTION_* constants for conn.status of newer PostgreSQL versions.
- Add better support for logical replication. [#339](https://github.com/ged/ruby-pg/pull/339)
- Change conn.socket_io to read+write mode and to a BasicSocket object instead of IO.
- Use rb_io_wait() and the conn.socket_io object if available for better compatibility to Fiber.scheduler .
  Fall back to rb_wait_for_single_fd() on ruby < 3.0.
- On Windows use a specialized wait function as a workaround for very poor performance of rb_io_wait(). [#416](https://github.com/ged/ruby-pg/pull/416)

Bugfixes:
- Release GVL while calling PQping which is a blocking method, but it didn't release GVL so far.
- Fix Connection#transaction to no longer block on interrupts, for instance when pressing Ctrl-C and cancel a running query. [#390](https://github.com/ged/ruby-pg/pull/390)
- Avoid casting of OIDs to fix compat with Redshift database. [#369](https://github.com/ged/ruby-pg/pull/369)
- Call conn.block before each conn.get_result call to avoid possible blocking in case of a slow network and multiple query results.
- Sporadic Errno::ENOTSOCK when using conn.socket_io on Windows [#398](https://github.com/ged/ruby-pg/pull/398)

Deprecated:
- Add deprecation warning to PG::BasicTypeRegistry.register_type and siblings.

Removed:
- Remove support of ruby-2.2, 2.3 and 2.4. Minimum is ruby-2.5 now.
- Remove support for PostgreSQL-9.2. Minimum is PostgreSQL-9.3 now.
- Remove constant PG::REVISION, which was broken since pg-1.1.4.

Repository:
- Replace Hoe by Bundler for gem packaging
- Add Github Actions CI and testing of source and binary gems.


## v1.2.3 [2020-03-18] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Fix possible segfault at `PG::Coder#encode`, `decode` or their implicit calls through
  a typemap after GC.compact. [#327](https://github.com/ged/ruby-pg/pull/327)
- Fix possible segfault in `PG::TypeMapByClass` after GC.compact. [#328](https://github.com/ged/ruby-pg/pull/328)


## v1.2.2 [2020-01-06] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Add a binary gem for Ruby 2.7.


## v1.2.1 [2020-01-02] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Added internal API for sequel_pg compatibility.


## v1.2.0 [2019-12-20] Michael Granger <ged@FaerieMUD.org>

Repository:
- Our primary repository has been moved to Github https://github.com/ged/ruby-pg .
  Most of the issues from https://bitbucket.org/ged/ruby-pg have been migrated. [#43](https://github.com/ged/ruby-pg/pull/43)

API enhancements:
- Add PG::Result#field_name_type= and siblings to allow symbols to be used as field names. [#306](https://github.com/ged/ruby-pg/pull/306)
- Add new methods for error reporting:
  - PG::Connection#set_error_context_visibility
  - PG::Result#verbose_error_message
  - PG::Result#result_verbose_error_message (alias)
- Update errorcodes and error classes to PostgreSQL-12.0.
- New constants: PG_DIAG_SEVERITY_NONLOCALIZED, PQERRORS_SQLSTATE, PQSHOW_CONTEXT_NEVER, PQSHOW_CONTEXT_ERRORS, PQSHOW_CONTEXT_ALWAYS

Type cast enhancements:
- Add PG::TextEncoder::Record and PG::TextDecoder::Record for en/decoding of Composite Types. [#258](https://github.com/ged/ruby-pg/pull/258), [#36](https://github.com/ged/ruby-pg/pull/36)
- Add PG::BasicTypeRegistry.register_coder to register instances instead of classes.
  This is useful to register parametrized en/decoders like PG::TextDecoder::Record .
- Add PG::BasicTypeMapForQueries#encode_array_as= to switch between various interpretations of ruby arrays.
- Add Time, Array<Time>, Array<BigDecimal> and Array<IPAddr> encoders to PG::BasicTypeMapForQueries
- Exchange sprintf based float encoder by very fast own implementation with more natural format. [#301](https://github.com/ged/ruby-pg/pull/301)
- Define encode and decode methods only in en/decoders that implement it, so that they can be queried by respond_to? .
- Improve PG::TypeMapByColumn#inspect
- Accept Integer and Float as input to TextEncoder::Numeric . [#310](https://github.com/ged/ruby-pg/pull/310)

Other enhancements:
- Allocate the data part and the ruby object of PG::Result in one step, so that we don't need to check for valid data.
  This removes PG::Result.allocate and PG::Result.new, which were callable but without any practical use. [#42](https://github.com/ged/ruby-pg/pull/42)
- Make use of PQresultMemorySize() of PostgreSQL-12 and fall back to our internal estimator.
- Improve performance of PG::Result#stream_each_tuple .
- Store client encoding in data part of PG::Connection and PG::Result objects, so that we no longer use ruby's internal encoding bits. [#280](https://github.com/ged/ruby-pg/pull/280)
- Update Windows fat binary gem to OpenSSL-1.1.1d and PostgreSQL-12.1.
- Add support for TruffleRuby. It is regularly tested as part of our CI.
- Enable +frozen_string_literal+ in all pg's ruby files

Bugfixes:
- Update the license in gemspec to "BSD-2-Clause".
  It was incorrectly labeled "BSD-3-Clause". [#40](https://github.com/ged/ruby-pg/pull/40)
- Respect PG::Coder#flags in PG::Coder#to_h.
- Fix PG::Result memsize reporting after #clear.
- Release field names to GC on PG::Result#clear.
- Fix double free in PG::Result#stream_each_tuple when an exception is raised in the block.
- Fix PG::Result#stream_each_tuple to deliver typemapped values.
- Fix encoding of Array<unknown> with PG::BasicTypeMapForQueries

Deprecated:
- Add a deprecation warning to PG::Connection#socket .

Removed:
- Remove PG::Connection#guess_result_memsize= which was temporary added in pg-1.1.
- Remove PG::Result.allocate and PG::Result.new (see enhancements).
- Remove support of tainted objects. [#307](https://github.com/ged/ruby-pg/pull/307)
- Remove support of ruby-2.0 and 2.1. Minimum is ruby-2.2 now.

Documentation:
- Update description of connection params. See PG::Connection.new
- Link many method descriptions to corresponding libpq's documentation.
- Update sync_* and async_* query method descriptions and document the aliases.
  The primary documentation is now at the async_* methods which are the default since pg-1.1.
- Fix documentation of many constants


## v1.1.4 [2019-01-08] Michael Granger <ged@FaerieMUD.org>

- Fix PG::BinaryDecoder::Timestamp on 32 bit systems. # 284
- Add new error-codes of PostgreSQL-11.
- Add ruby-2.6 support for Windows fat binary gems and remove ruby-2.0 and 2.1.


## v1.1.3 [2018-09-06] Michael Granger <ged@FaerieMUD.org>

- Revert opimization that was sometimes causing EBADF in rb_wait_for_single_fd().


## v1.1.2 [2018-08-28] Michael Granger <ged@FaerieMUD.org>

- Don't generate aliases for JOHAB encoding.
  This avoids linking to deprecated/private function rb_enc(db)_alias().


## v1.1.1 [2018-08-27] Michael Granger <ged@FaerieMUD.org>

- Reduce deprecation warnings to only one message per deprecation.


## v1.1.0 [2018-08-24] Michael Granger <ged@FaerieMUD.org>

Deprecated (disable warnings per PG_SKIP_DEPRECATION_WARNING=1):
- Forwarding conn.exec to conn.exec_params is deprecated.
- Forwarding conn.exec_params to conn.exec is deprecated.
- Forwarding conn.async_exec to conn.async_exec_params.
- Forwarding conn.send_query to conn.send_query_params is deprecated.
- Forwarding conn.async_exec_params to conn.async_exec is deprecated.

PG::Connection enhancements:
- Provide PG::Connection#sync_* and PG::Connection#async_* query methods for explicit calling synchronous or asynchronous libpq API.
- Make PG::Connection#exec and siblings switchable between sync and async API per PG::Connection.async_api= and change the default to async flavors.
- Add async flavors of exec_params, prepare, exec_prepared, describe_prepared and describe_portal.
  They are identical to their synchronous counterpart, but make use of PostgreSQL's async API.
- Replace `rb_thread_fd_select()` by faster `rb_wait_for_single_fd()` in `conn.block` and `conn.async_exec` .
- Add PG::Connection#discard_results .
- Raise an ArgumentError for strings containing zero bytes by #escape, #escape_literal, #escape_identifier, #quote_ident and PG::TextEncoder::Identifier. These methods previously truncated strings.

Result retrieval enhancements:
- Add PG::Result#tuple_values to retrieve all field values of a row as array.
- Add PG::Tuple, PG::Result#tuple and PG::Result#stream_each_tuple .
  PG::Tuple offers a way to lazy cast result values.
- Estimate PG::Result size allocated by libpq and notify the garbage collector about it when running on Ruby-2.4 or newer.
- Make the estimated PG::Result size available to ObjectSpace.memsize_of(result) .

Type cast enhancements:
- Replace Ruby code by a faster C implementation of the SimpleDecoder's timestamp decode functions. github [#20](https://github.com/ged/ruby-pg/pull/20)
- Interpret years with up to 7 digists and BC dates by timestamp decoder.
- Add text timestamp decoders for UTC vs. local timezone variations.
- Add text timestamp encoders for UTC timezone.
- Add decoders for binary timestamps: PG::BinaryDecoder::Timestamp and variations.
- Add PG::Coder#flags accessor to allow modifications of de- respectively encoder behaviour.
- Add a flag to raise TypeError for invalid input values to PG::TextDecoder::Array .
- Add a text decoder for inet/cidr written in C.
- Add a numeric decoder written in C.
- Ensure input text is zero terminated for text format in PG::Coder#decode .

Source code enhancements:
- Fix headers and permission bits of various repository files.

Bugfixes:
- Properly decode array with prepended dimensions. [#272](https://github.com/ged/ruby-pg/pull/272)
  For now dimension decorations are ignored, but a correct Array is returned.
- Array-Decoder: Avoid leaking memory when an Exception is raised while parsing. Fixes [#279](https://github.com/ged/ruby-pg/pull/279)


## v1.0.0 [2018-01-10] Michael Granger <ged@FaerieMUD.org>

Deprecated:
- Deprecate Ruby older than 2.2.
- Deprecate Connection#socket in favor of #socket_io.

Removed:
- Remove compatibility code for Ruby < 2.0 and PostgreSQL < 9.2.
- Remove partial compatibility with Rubinius.
- Remove top-level constants PGconn, PGresult, and PGError.

Enhancements:
- Update error codes to PostgreSQL-10
- Update Windows binary gems to Ruby-2.5, PostgreSQL 10.1 and
  OpenSSL 1.1.0g.

Bugfixes:
- Fix URI detection for connection strings. [#265](https://github.com/ged/ruby-pg/pull/265) (thanks to jjoos)
- MINGW: Workaround segfault due to GCC linker error in conjunction with MSVC.
  This happens when linking to PostgreSQL-10.0-x64 from EnterpriseDB.

Documentation fixes:
- Add PostgreSQL version since when the given function is supported. [#263](https://github.com/ged/ruby-pg/pull/263)
- Better documentation to `encoder` and `decoder` arguments of COPY related methods.


## v0.21.0 [2017-06-12] Michael Granger <ged@FaerieMUD.org>

Enhancements:
- Move add_dll_directory to the Runtime namespace for newest versions
  of RubyInstaller.
- Deprecate PGconn, PGresult, and PGError top-level constants; a warning
  will be output the first time one of them is used. They will be
  removed in the upcoming 1.0 release.

Documentation fixes:
- Update the docs for PG::Result#cmd_tuples

New Samples:
- Add an example of the nicer #copy_data way of doing `COPY`.


## v0.20.0 [2017-03-10] Michael Granger <ged@FaerieMUD.org>

Enhancements:
- Update error codes to PostgreSQL-9.6
- Update Windows binary gems to Ruby-2.4, PostgreSQL 9.6.1 and
  OpenSSL 1.0.2j.
- Add support for RubyInstaller2 to Windows binary gems.

Bugfixes:
- Use secure JSON methods for JSON (de)serialisation. [#248](https://github.com/ged/ruby-pg/pull/248)
- Fix Result#inspect on a cleared result.
- Fix test case that failed on Ruby-2.4. [#255](https://github.com/ged/ruby-pg/pull/255)

Documentation fixes:
- Talk about Integer instead of Fixnum.
- Fix method signature of Coder#encode.


## v0.19.0 [2016-09-21] Michael Granger <ged@FaerieMUD.org>

- Deprecate Ruby 1.9

Enhancements:
- Respect and convert character encoding of all strings sent
  to the server. [#231](https://github.com/ged/ruby-pg/pull/231)
- Add PostgreSQL-9.5 functions PQsslInUse(), PQsslAttribute()
  and PQsslAttributeNames().
- Various documentation fixes and improvements.
- Add mechanism to build without pg_config:
    gem install pg -- --with-pg-config=ignore
- Update Windows binary gems to Ruby-2.3, PostgreSQL 9.5.4 and
  OpenSSL 1.0.2f.
- Add JSON coders and add them to BasicTypeMapForResults and
  BasicTypeMapBasedOnResult
- Allow build from git per bundler.

Bugfixes:
- Release GVL while calling PQsetClientEncoding(). [#245](https://github.com/ged/ruby-pg/pull/245)
- Add __EXTENSIONS__ to Solaris/SmartOS for Ruby >= 2.3.x. [#236](https://github.com/ged/ruby-pg/pull/236)
- Fix wrong exception when running SQL while in Connection#copy_data
  block for output


## v0.18.4 [2015-11-13] Michael Granger <ged@FaerieMUD.org>

Enhancements:
- Fixing compilation problems with Microsoft Visual Studio 2008. GH [#10](https://github.com/ged/ruby-pg/pull/10)
- Avoid name clash with xcode and jemalloc. PR[#22](https://github.com/ged/ruby-pg/pull/22), PR[#23](https://github.com/ged/ruby-pg/pull/23)

Bugfixes:
- Avoid segfault, when quote_ident or TextEncoder::Identifier
  is called with Array containing non-strings. [#226](https://github.com/ged/ruby-pg/pull/226)


## v0.18.3 [2015-09-03] Michael Granger <ged@FaerieMUD.org>

Enhancements:
- Use rake-compiler-dock to build windows gems easily.
- Add CI-tests on appveyor and fix test cases accordingly.

Bugfixes:
- Fix data type resulting in wrong base64 encoding.
- Change instance_of checks to kind_of for subclassing. [#220](https://github.com/ged/ruby-pg/pull/220)
- TextDecoder::Date returns an actual Ruby Date instead of a Time
  (thanks to Thomas Ramfjord)


## v0.18.2 [2015-05-14] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Allow URI connection string (thanks to Chris Bandy)
- Allow Array type parameter to conn.quote_ident

Bugfixes:

- Speedups and fixes for PG::TextDecoder::Identifier and quoting behavior
- Revert addition of PG::Connection#hostaddr [[#202](https://github.com/ged/ruby-pg/pull/202)].
- Fix decoding of fractional timezones and timestamps [[#203](https://github.com/ged/ruby-pg/pull/203)]
- Fixes for non-C99 compilers
- Avoid possible symbol name clash when linking against static libpq.


## v0.18.1 [2015-01-05] Michael Granger <ged@FaerieMUD.org>

Correct the minimum compatible Ruby version to 1.9.3. [#199](https://github.com/ged/ruby-pg/pull/199)


## v0.18.0 [2015-01-01] Michael Granger <ged@FaerieMUD.org>

Bugfixes:
- Fix OID to Integer mapping (it is unsigned now). [#187](https://github.com/ged/ruby-pg/pull/187)
- Fix possible segfault in conjunction with notice receiver. [#185](https://github.com/ged/ruby-pg/pull/185)

Enhancements:

- Add an extensible type cast system.
- A lot of performance improvements.
- Return frozen String objects for result field names.
- Add PG::Result#stream_each and #stream_each_row as fast helpers for
  the single row mode.
- Add Enumerator variant to PG::Result#each and #each_row.
- Add PG::Connection#conninfo and #hostaddr.
- Add PG.init_openssl and PG.init_ssl methods.
- Add PG::Result.inspect
- Force zero termination for all text strings that are given to libpq.
  It raises an ArgumentError if the string contains a null byte.
- Update Windows cross build to PostgreSQL 9.3.



## v0.17.1 [2013-12-18] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Fix compatibility with signal handlers defined in Ruby. This reverts
  cancellation of queries running on top of the blocking libpq API (like
  Connection#exec) in case of signals. As an alternative the #async_exec
  can be used, which is reverted to use the non-blocking API, again.
- Wrap PQcancel to be called without GVL. It internally waits for
  the canceling connection.

Documentation fixes:

- Fix documentation for PG::Connection::conndefaults.


## v0.17.0 [2013-09-15] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Fix crash by calling PQsend* and PQisBusy without GVL ([#171](https://github.com/ged/ruby-pg/pull/171)).

Enhancements:

- Add method PG::Connection#copy_data.
- Add a Gemfile to allow installation of dependencies with bundler.
- Add compatibility with rake-compiler-dev-box.
- Return self from PG::Result#check instead of nil. This allows
  to stack method calls.


## v0.16.0 [2013-07-22] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Avoid warnings about uninitialized instance variables.
- Use a more standard method of adding library and include directories.
  This fixes build on AIX (Github [#7](https://github.com/ged/ruby-pg/pull/7)) and Solaris ([#164](https://github.com/ged/ruby-pg/pull/164)).
- Cancel the running query, if a thread is about to be killed (e.g. by CTRL-C).
- Fix GVL issue with wait_for_notify/notifies and notice callbacks.
- Set proper encoding on the string returned by quote_ident, escape_literal
  and escape_identifier ([#163](https://github.com/ged/ruby-pg/pull/163)).
- Use nil as PG::Error#result in case of a NULL-result from libpq ([#166](https://github.com/ged/ruby-pg/pull/166)).
- Recalculate the timeout of conn#wait_for_notify and conn#block in case
  of socket events that require re-runs of select().

Documentation fixes:

- Fix non working example for PGresult#error_field.

Enhancements:

- Add unique exception classes for each PostgreSQL error type ([#5](https://github.com/ged/ruby-pg/pull/5)).
- Return result of the block in conn#transaction instead of nil ([#158](https://github.com/ged/ruby-pg/pull/158)).
- Allow 'rake compile' and 'rake gem' on non mercurial repos.
- Add support for PG_DIAG_*_NAME error fields of PostgreSQL-9.3 ([#161](https://github.com/ged/ruby-pg/pull/161)).


## v0.15.1 [2013-04-08] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Shorten application_name to avoid warnings about truncated identifier.


## v0.15.0 [2013-03-03] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Fix segfault in PG::Result#field_values when called with non String value.
- Fix encoding of messages delivered by notice callbacks.
- Fix text encoding for Connection#wait_for_notify and Connection#notifies.
- Fix 'Bad file descriptor' problems under Windows: wrong behaviour of
  #wait_for_notify() and timeout handling of #block on Ruby 1.9.

Documentation fixes:

- conn#socket() can not be used with IO.for_fd() on Windows.

Enhancements:

- Tested under Ruby 2.0.0p0.
- Add single row mode of PostgreSQL 9.2.
- Set fallback_application_name to program name $0. Thanks to Will Leinweber
  for the patch.
- Release Ruby's GVL while calls to blocking libpq functions to allow better
  concurrency in threaded applications.
- Refactor different variants of waiting for the connection socket.
- Make use of rb_thread_fd_select() on Ruby 1.9 and avoid deprecated
  rb_thread_select().
- Add an example of how to insert array data using a prepared statement ([#145](https://github.com/ged/ruby-pg/pull/145)).
- Add continuous integration tests on travis-ci.org.
- Add PG::Result#each_row for iterative over result sets by row. Thanks to
  Aaron Patterson for the patch.
- Add a PG::Connection#socket_io method for fetching a (non-autoclosing) IO
  object for the connection's socket.

Specs:

- Fix various specs to run on older PostgreSQL and Ruby versions.
- Avoid fork() in specs to allow usage on Windows and JRuby.


## v0.14.1 [2012-09-02] Michael Granger <ged@FaerieMUD.org>

Important bugfix:

- Fix stack overflow bug in PG::Result#values and #column_values ([#135](https://github.com/ged/ruby-pg/pull/135)). Thanks
  to everyone who reported the bug, and Lars Kanis especially for figuring out
  the problem.

PostgreSQL 9.2 beta fixes:

- Recognize PGRES_SINGLE_TUPLE as OK when checking PGresult (Jeremy Evans)

Documentation fixes:

- Add note about the usage scope of the result object received by the
  #set_notice_receiver block. (Lars Kanis)
- Add PGRES_COPY_BOTH to documentation of PG::Result#result_status. (Lars Kanis)
- Add some documentation to PG::Result#fnumber (fix for [#139](https://github.com/ged/ruby-pg/pull/139))


## v0.14.0 [2012-06-17] Michael Granger <ged@FaerieMUD.org>

Bugfixes:
  [#47](https://github.com/ged/ruby-pg/pull/47), [#104](https://github.com/ged/ruby-pg/pull/104)


New Methods for PostgreSQL 9 and async API support:
PG
- ::library_version

PG::Connection
- ::ping
- #escape_literal
- #escape_identifier
- #set_default_encoding

PG::Result
- #check


New Samples:

This release also comes with a collection of contributed sample scripts for
doing resource-utilization reports, graphing database statistics,
monitoring for replication lag, shipping WAL files for replication,
automated tablespace partitioning, etc. See the samples/ directory.


## v0.13.2 [2012-02-22] Michael Granger <ged@FaerieMUD.org>

- Make builds against PostgreSQL earlier than 8.3 fail with a descriptive
  message instead of a compile failure.


## v0.13.1 [2012-02-12] Michael Granger <ged@FaerieMUD.org>

- Made use of a finished PG::Connection raise a PG::Error instead of
  a fatal error ([#110](https://github.com/ged/ruby-pg/pull/110)).
- Added missing BSDL license file ([#108](https://github.com/ged/ruby-pg/pull/108))


## v0.13.0 [2012-02-09] Michael Granger <ged@FaerieMUD.org>

Reorganization of modules/classes to be better Ruby citizens (with backward-compatible aliases):
- Created toplevel namespace 'PG' to correspond with the gem name.
- Renamed PGconn to PG::Connection (with ::PGconn alias)
- Renamed PGresult to PG::Result (with ::PGresult alias)
- Renamed PGError to PG::Error (with ::PGError alias)
- Declare all constants inside PG::Constants, then include them in
  PG::Connection and PG::Result for backward-compatibility, and
  in PG for convenience.
- Split the extension source up by class/module.
- Removed old compatibility code for PostgreSQL versions < 8.3

Documentation:
- Clarified licensing, updated to Ruby 1.9's license.
- Merged authors list, added some missing people to the Contributor's
  list.
- Cleaned up the sample/ directory
- Making contact info a bit clearer, link to the Google+ page and
  the mailing list

Enhancements:
- Added a convenience method: PG.connect -> PG::Connection.new

Bugfixes:
- Fixed LATIN5-LATIN10 Postgres<->Ruby encoding conversions



## v0.12.2 [2012-01-03] Michael Granger <ged@FaerieMUD.org>

- Fix for the 1.8.7 breakage introduced by the st.h fix for alternative Ruby
  implementations ([#97](https://github.com/ged/ruby-pg/pull/97) and [#98](https://github.com/ged/ruby-pg/pull/98)). Thanks to Lars Kanis for the patch.
- Encode error messages with the connection's encoding under 1.9 ([#96](https://github.com/ged/ruby-pg/pull/96))


## v0.12.1 [2011-12-14] Michael Granger <ged@FaerieMUD.org>

- Made rake-compiler a dev dependency, as Rubygems doesn't use the Rakefile
  for compiling the extension. Thanks to eolamey@bitbucket and Jeremy Evans
  for pointing this out.
- Added an explicit include for ruby/st.h for implementations that need it
  (fixes [#95](https://github.com/ged/ruby-pg/pull/95)).


## v0.12.0 [2011-12-07] Michael Granger <ged@FaerieMUD.org>

- PGconn#wait_for_notify
  * send nil as the payload argument if the NOTIFY didn't have one.
  * accept a nil argument for no timeout (Sequel support)
  * Fixed API docs
  * Taint and encode event name and payload
- Handle errors while rb_thread_select()ing in PGconn#block.
  (Brian Weaver).
- Fixes for Win32 async queries (Rafał Bigaj)
- Memory leak fixed: Closing opened WSA event. (rafal)
- Fixes for [#66](https://github.com/ged/ruby-pg/pull/66) Win32 asynchronous queries hang on connection
  error. (rafal)
- Fixed a typo in PGconn#error_message's documentation
- fixing unused variable warnings for ruby 1.9.3 (Aaron Patterson)
- Build system bugfixes
- Converted to Hoe
- Updates for the Win32 binary gem builds (Lars Kanis)


## v0.11.0 [2011-02-09] Michael Granger <ged@FaerieMUD.org>

Enhancements:

* Added a PGresult#values method to fetch all result rows as an Array of
  Arrays. Thanks to Jason Yanowitz (JYanowitz at enovafinancial dot com) for
  the patch.


## v0.10.1 [2011-01-19] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

* Add an include guard for pg.h
* Simplify the common case require of the ext
* Include the extconf header
* Fix compatibility with versions of PostgreSQL without PQgetCancel. (fixes [#36](https://github.com/ged/ruby-pg/pull/36))
* Fix require for natively-compiled extension under Windows. (fixes [#55](https://github.com/ged/ruby-pg/pull/55))
* Change rb_yield_splat() to rb_yield_values() for compatibility with Rubinius. (fixes [#54](https://github.com/ged/ruby-pg/pull/54))


## v0.10.0 [2010-12-01] Michael Granger <ged@FaerieMUD.org>

Enhancements:

* Added support for the payload of NOTIFY events (w/Mahlon E. Smith)
* Updated the build system with Rubygems suggestions from RubyConf 2010

Bugfixes:

* Fixed issue with PGconn#wait_for_notify that caused it to miss notifications that happened after
  the LISTEN but before the wait_for_notify.

## v0.9.0 [2010-02-28] Michael Granger <ged@FaerieMUD.org>

Bugfixes.

## v0.8.0 [2009-03-28] Jeff Davis <davis.jeffrey@gmail.com>

Bugfixes, better Windows support.

