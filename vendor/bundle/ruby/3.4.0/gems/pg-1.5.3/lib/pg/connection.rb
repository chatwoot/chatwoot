# -*- ruby -*-
# frozen_string_literal: true

require 'pg' unless defined?( PG )
require 'io/wait' unless ::IO.public_instance_methods(false).include?(:wait_readable)
require 'socket'

# The PostgreSQL connection class. The interface for this class is based on
# {libpq}[http://www.postgresql.org/docs/current/libpq.html], the C
# application programmer's interface to PostgreSQL. Some familiarity with libpq
# is recommended, but not necessary.
#
# For example, to send query to the database on the localhost:
#
#    require 'pg'
#    conn = PG::Connection.open(:dbname => 'test')
#    res = conn.exec_params('SELECT $1 AS a, $2 AS b, $3 AS c', [1, 2, nil])
#    # Equivalent to:
#    #  res  = conn.exec('SELECT 1 AS a, 2 AS b, NULL AS c')
#
# See the PG::Result class for information on working with the results of a query.
#
# Many methods of this class have three variants kind of:
# 1. #exec - the base method which is an alias to #async_exec .
#    This is the method that should be used in general.
# 2. #async_exec - the async aware version of the method, implemented by libpq's async API.
# 3. #sync_exec - the method version that is implemented by blocking function(s) of libpq.
#
# Sync and async version of the method can be switched by Connection.async_api= , however it is not recommended to change the default.
class PG::Connection

	# The order the options are passed to the ::connect method.
	CONNECT_ARGUMENT_ORDER = %w[host port options tty dbname user password].freeze
	private_constant :CONNECT_ARGUMENT_ORDER

	### Quote a single +value+ for use in a connection-parameter string.
	def self.quote_connstr( value )
		return "'" + value.to_s.gsub( /[\\']/ ) {|m| '\\' + m } + "'"
	end

	# Convert Hash options to connection String
	#
	# Values are properly quoted and escaped.
	def self.connect_hash_to_string( hash )
		hash.map { |k,v| "#{k}=#{quote_connstr(v)}" }.join( ' ' )
	end

	# Shareable program name for Ractor
	PROGRAM_NAME = $PROGRAM_NAME.dup.freeze
	private_constant :PROGRAM_NAME

	# Parse the connection +args+ into a connection-parameter string.
	# See PG::Connection.new for valid arguments.
	#
	# It accepts:
	# * an option String kind of "host=name port=5432"
	# * an option Hash kind of {host: "name", port: 5432}
	# * URI string
	# * URI object
	# * positional arguments
	#
	# The method adds the option "fallback_application_name" if it isn't already set.
	# It returns a connection string with "key=value" pairs.
	def self.parse_connect_args( *args )
		hash_arg = args.last.is_a?( Hash ) ? args.pop.transform_keys(&:to_sym) : {}
		iopts = {}

		if args.length == 1
			case args.first.to_s
			when /=/, /:\/\//
				# Option or URL string style
				conn_string = args.first.to_s
				iopts = PG::Connection.conninfo_parse(conn_string).each_with_object({}){|h, o| o[h[:keyword].to_sym] = h[:val] if h[:val] }
			else
				# Positional parameters (only host given)
				iopts[CONNECT_ARGUMENT_ORDER.first.to_sym] = args.first
			end
		else
			# Positional parameters with host and more
			max = CONNECT_ARGUMENT_ORDER.length
			raise ArgumentError,
					"Extra positional parameter %d: %p" % [ max + 1, args[max] ] if args.length > max

			CONNECT_ARGUMENT_ORDER.zip( args ) do |(k,v)|
				iopts[ k.to_sym ] = v if v
			end
			iopts.delete(:tty) # ignore obsolete tty parameter
		end

		iopts.merge!( hash_arg )

		if !iopts[:fallback_application_name]
			iopts[:fallback_application_name] = PROGRAM_NAME.sub( /^(.{30}).{4,}(.{30})$/ ){ $1+"..."+$2 }
		end

		return connect_hash_to_string(iopts)
	end

	# Return a String representation of the object suitable for debugging.
	def inspect
		str = self.to_s
		str[-1,0] = if finished?
			" finished"
		else
			stats = []
			stats << " status=#{ PG.constants.grep(/CONNECTION_/).find{|c| PG.const_get(c) == status} }" if status != CONNECTION_OK
			stats << " transaction_status=#{ PG.constants.grep(/PQTRANS_/).find{|c| PG.const_get(c) == transaction_status} }" if transaction_status != PG::PQTRANS_IDLE
			stats << " nonblocking=#{ isnonblocking }" if isnonblocking
			stats << " pipeline_status=#{ PG.constants.grep(/PQ_PIPELINE_/).find{|c| PG.const_get(c) == pipeline_status} }" if respond_to?(:pipeline_status) && pipeline_status != PG::PQ_PIPELINE_OFF
			stats << " client_encoding=#{ get_client_encoding }" if get_client_encoding != "UTF8"
			stats << " type_map_for_results=#{ type_map_for_results.to_s }" unless type_map_for_results.is_a?(PG::TypeMapAllStrings)
			stats << " type_map_for_queries=#{ type_map_for_queries.to_s }" unless type_map_for_queries.is_a?(PG::TypeMapAllStrings)
			stats << " encoder_for_put_copy_data=#{ encoder_for_put_copy_data.to_s }" if encoder_for_put_copy_data
			stats << " decoder_for_get_copy_data=#{ decoder_for_get_copy_data.to_s }" if decoder_for_get_copy_data
			" host=#{host} port=#{port} user=#{user}#{stats.join}"
		end
		return str
	end

	BinarySignature = "PGCOPY\n\377\r\n\0".b
	private_constant :BinarySignature

	#  call-seq:
	#     conn.copy_data( sql [, coder] ) {|sql_result| ... } -> PG::Result
	#
	# Execute a copy process for transferring data to or from the server.
	#
	# This issues the SQL COPY command via #exec. The response to this
	# (if there is no error in the command) is a PG::Result object that
	# is passed to the block, bearing a status code of PGRES_COPY_OUT or
	# PGRES_COPY_IN (depending on the specified copy direction).
	# The application should then use #put_copy_data or #get_copy_data
	# to receive or transmit data rows and should return from the block
	# when finished.
	#
	# #copy_data returns another PG::Result object when the data transfer
	# is complete. An exception is raised if some problem was encountered,
	# so it isn't required to make use of any of them.
	# At this point further SQL commands can be issued via #exec.
	# (It is not possible to execute other SQL commands using the same
	# connection while the COPY operation is in progress.)
	#
	# This method ensures, that the copy process is properly terminated
	# in case of client side or server side failures. Therefore, in case
	# of blocking mode of operation, #copy_data is preferred to raw calls
	# of #put_copy_data, #get_copy_data and #put_copy_end.
	#
	# _coder_ can be a PG::Coder derivation
	# (typically PG::TextEncoder::CopyRow or PG::TextDecoder::CopyRow).
	# This enables encoding of data fields given to #put_copy_data
	# or decoding of fields received by #get_copy_data.
	#
	# Example with CSV input format:
	#   conn.exec "create table my_table (a text,b text,c text,d text)"
	#   conn.copy_data "COPY my_table FROM STDIN CSV" do
	#     conn.put_copy_data "some,data,to,copy\n"
	#     conn.put_copy_data "more,data,to,copy\n"
	#   end
	# This creates +my_table+ and inserts two CSV rows.
	#
	# The same with text format encoder PG::TextEncoder::CopyRow
	# and Array input:
	#   enco = PG::TextEncoder::CopyRow.new
	#   conn.copy_data "COPY my_table FROM STDIN", enco do
	#     conn.put_copy_data ['some', 'data', 'to', 'copy']
	#     conn.put_copy_data ['more', 'data', 'to', 'copy']
	#   end
	#
	# Also PG::BinaryEncoder::CopyRow can be used to send data in binary format to the server.
	# In this case copy_data generates the header and trailer data automatically:
	#   enco = PG::BinaryEncoder::CopyRow.new
	#   conn.copy_data "COPY my_table FROM STDIN (FORMAT binary)", enco do
	#     conn.put_copy_data ['some', 'data', 'to', 'copy']
	#     conn.put_copy_data ['more', 'data', 'to', 'copy']
	#   end
	#
	# Example with CSV output format:
	#   conn.copy_data "COPY my_table TO STDOUT CSV" do
	#     while row=conn.get_copy_data
	#       p row
	#     end
	#   end
	# This prints all rows of +my_table+ to stdout:
	#   "some,data,to,copy\n"
	#   "more,data,to,copy\n"
	#
	# The same with text format decoder PG::TextDecoder::CopyRow
	# and Array output:
	#   deco = PG::TextDecoder::CopyRow.new
	#   conn.copy_data "COPY my_table TO STDOUT", deco do
	#     while row=conn.get_copy_data
	#       p row
	#     end
	#   end
	# This receives all rows of +my_table+ as ruby array:
	#   ["some", "data", "to", "copy"]
	#   ["more", "data", "to", "copy"]
	#
	# Also PG::BinaryDecoder::CopyRow can be used to retrieve data in binary format from the server.
	# In this case the header and trailer data is processed by the decoder and the remaining +nil+ from get_copy_data is processed by copy_data, so that binary data can be processed equally to text data:
	#   deco = PG::BinaryDecoder::CopyRow.new
	#   conn.copy_data "COPY my_table TO STDOUT (FORMAT binary)", deco do
	#     while row=conn.get_copy_data
	#       p row
	#     end
	#   end
	# This receives all rows of +my_table+ as ruby array:
	#   ["some", "data", "to", "copy"]
	#   ["more", "data", "to", "copy"]

	def copy_data( sql, coder=nil )
		raise PG::NotInBlockingMode.new("copy_data can not be used in nonblocking mode", connection: self) if nonblocking?
		res = exec( sql )

		case res.result_status
		when PGRES_COPY_IN
			begin
				if coder && res.binary_tuples == 1
					# Binary file header (11 byte signature, 32 bit flags and 32 bit extension length)
					put_copy_data(BinarySignature + ("\x00" * 8))
				end

				if coder
					old_coder = self.encoder_for_put_copy_data
					self.encoder_for_put_copy_data = coder
				end

				yield res
			rescue Exception => err
				errmsg = "%s while copy data: %s" % [ err.class.name, err.message ]
				begin
					put_copy_end( errmsg )
				rescue PG::Error
					# Ignore error in cleanup to avoid losing original exception
				end
				discard_results
				raise err
			else
				begin
					self.encoder_for_put_copy_data = old_coder if coder

					if coder && res.binary_tuples == 1
						put_copy_data("\xFF\xFF") # Binary file trailer 16 bit "-1"
					end

					put_copy_end
				rescue PG::Error => err
					raise PG::LostCopyState.new("#{err} (probably by executing another SQL query while running a COPY command)", connection: self)
				end
				get_last_result
			ensure
				self.encoder_for_put_copy_data = old_coder if coder
			end

		when PGRES_COPY_OUT
			begin
				if coder
					old_coder = self.decoder_for_get_copy_data
					self.decoder_for_get_copy_data = coder
				end
				yield res
			rescue Exception
				cancel
				discard_results
				raise
			else
				if coder && res.binary_tuples == 1
					# There are two end markers in binary mode: file trailer and the final nil.
					# The file trailer is expected to be processed by BinaryDecoder::CopyRow and already returns nil, so that the remaining NULL from PQgetCopyData is retrieved here:
					if get_copy_data
						discard_results
						raise PG::NotAllCopyDataRetrieved.new("Not all binary COPY data retrieved", connection: self)
					end
				end
				res = get_last_result
				if !res
					discard_results
					raise PG::LostCopyState.new("Lost COPY state (probably by executing another SQL query while running a COPY command)", connection: self)
				elsif res.result_status != PGRES_COMMAND_OK
					discard_results
					raise PG::NotAllCopyDataRetrieved.new("Not all COPY data retrieved", connection: self)
				end
				res
			ensure
				self.decoder_for_get_copy_data = old_coder if coder
			end

		else
			raise ArgumentError, "SQL command is no COPY statement: #{sql}"
		end
	end

	# Backward-compatibility aliases for stuff that's moved into PG.
	class << self
		define_method( :isthreadsafe, &PG.method(:isthreadsafe) )
	end

	#
	# call-seq:
	#    conn.transaction { |conn| ... } -> result of the block
	#
	# Executes a +BEGIN+ at the start of the block,
	# and a +COMMIT+ at the end of the block, or
	# +ROLLBACK+ if any exception occurs.
	def transaction
		rollback = false
		exec "BEGIN"
		yield(self)
	rescue Exception
		rollback = true
		cancel if transaction_status == PG::PQTRANS_ACTIVE
		block
		exec "ROLLBACK"
		raise
	ensure
		exec "COMMIT" unless rollback
	end

	### Returns an array of Hashes with connection defaults. See ::conndefaults
	### for details.
	def conndefaults
		return self.class.conndefaults
	end

	### Return the Postgres connection defaults structure as a Hash keyed by option
	### keyword (as a Symbol).
	###
	### See also #conndefaults
	def self.conndefaults_hash
		return self.conndefaults.each_with_object({}) do |info, hash|
			hash[ info[:keyword].to_sym ] = info[:val]
		end
	end

	### Returns a Hash with connection defaults. See ::conndefaults_hash
	### for details.
	def conndefaults_hash
		return self.class.conndefaults_hash
	end

	### Return the Postgres connection info structure as a Hash keyed by option
	### keyword (as a Symbol).
	###
	### See also #conninfo
	def conninfo_hash
		return self.conninfo.each_with_object({}) do |info, hash|
			hash[ info[:keyword].to_sym ] = info[:val]
		end
	end

	# Method 'ssl_attribute' was introduced in PostgreSQL 9.5.
	if self.instance_methods.find{|m| m.to_sym == :ssl_attribute }
		# call-seq:
		#   conn.ssl_attributes -> Hash<String,String>
		#
		# Returns SSL-related information about the connection as key/value pairs
		#
		# The available attributes varies depending on the SSL library being used,
		# and the type of connection.
		#
		# See also #ssl_attribute
		def ssl_attributes
			ssl_attribute_names.each.with_object({}) do |n,h|
				h[n] = ssl_attribute(n)
			end
		end
	end

	# Read all pending socket input to internal memory and raise an exception in case of errors.
	#
	# This verifies that the connection socket is in a usable state and not aborted in any way.
	# No communication is done with the server.
	# Only pending data is read from the socket - the method doesn't wait for any outstanding server answers.
	#
	# Raises a kind of PG::Error if there was an error reading the data or if the socket is in a failure state.
	#
	# The method doesn't verify that the server is still responding.
	# To verify that the communication to the server works, it is recommended to use something like <tt>conn.exec('')</tt> instead.
	def check_socket
		while socket_io.wait_readable(0)
			consume_input
		end
		nil
	end

	# call-seq:
	#    conn.get_result() -> PG::Result
	#    conn.get_result() {|pg_result| block }
	#
	# Blocks waiting for the next result from a call to
	# #send_query (or another asynchronous command), and returns
	# it. Returns +nil+ if no more results are available.
	#
	# Note: call this function repeatedly until it returns +nil+, or else
	# you will not be able to issue further commands.
	#
	# If the optional code block is given, it will be passed <i>result</i> as an argument,
	# and the PG::Result object will  automatically be cleared when the block terminates.
	# In this instance, <code>conn.exec</code> returns the value of the block.
	def get_result
		block
		sync_get_result
	end
	alias async_get_result get_result

	# call-seq:
	#    conn.get_copy_data( [ nonblock = false [, decoder = nil ]] ) -> Object
	#
	# Return one row of data, +nil+
	# if the copy is done, or +false+ if the call would
	# block (only possible if _nonblock_ is true).
	#
	# If _decoder_ is not set or +nil+, data is returned as binary string.
	#
	# If _decoder_ is set to a PG::Coder derivation, the return type depends on this decoder.
	# PG::TextDecoder::CopyRow decodes the received data fields from one row of PostgreSQL's
	# COPY text format to an Array of Strings.
	# Optionally the decoder can type cast the single fields to various Ruby types in one step,
	# if PG::TextDecoder::CopyRow#type_map is set accordingly.
	#
	# See also #copy_data.
	#
	def get_copy_data(async=false, decoder=nil)
		if async
			return sync_get_copy_data(async, decoder)
		else
			while (res=sync_get_copy_data(true, decoder)) == false
				socket_io.wait_readable
				consume_input
			end
			return res
		end
	end
	alias async_get_copy_data get_copy_data


	# In async_api=true mode (default) all send calls run nonblocking.
	# The difference is that setnonblocking(true) disables automatic handling of would-block cases.
	# In async_api=false mode all send calls run directly on libpq.
	# Blocking vs. nonblocking state can be changed in libpq.

	# call-seq:
	#    conn.setnonblocking(Boolean) -> nil
	#
	# Sets the nonblocking status of the connection.
	# In the blocking state, calls to #send_query
	# will block until the message is sent to the server,
	# but will not wait for the query results.
	# In the nonblocking state, calls to #send_query
	# will return an error if the socket is not ready for
	# writing.
	# Note: This function does not affect #exec, because
	# that function doesn't return until the server has
	# processed the query and returned the results.
	#
	# Returns +nil+.
	def setnonblocking(enabled)
		singleton_class.async_send_api = !enabled
		self.flush_data = !enabled
		sync_setnonblocking(true)
	end
	alias async_setnonblocking setnonblocking

	# sync/async isnonblocking methods are switched by async_setnonblocking()

	# call-seq:
	#    conn.isnonblocking() -> Boolean
	#
	# Returns the blocking status of the database connection.
	# Returns +true+ if the connection is set to nonblocking mode and +false+ if blocking.
	def isnonblocking
		false
	end
	alias async_isnonblocking isnonblocking
	alias nonblocking? isnonblocking

	# call-seq:
	#    conn.put_copy_data( buffer [, encoder] ) -> Boolean
	#
	# Transmits _buffer_ as copy data to the server.
	# Returns true if the data was sent, false if it was
	# not sent (false is only possible if the connection
	# is in nonblocking mode, and this command would block).
	#
	# _encoder_ can be a PG::Coder derivation (typically PG::TextEncoder::CopyRow).
	# This encodes the data fields given as _buffer_ from an Array of Strings to
	# PostgreSQL's COPY text format inclusive proper escaping. Optionally
	# the encoder can type cast the fields from various Ruby types in one step,
	# if PG::TextEncoder::CopyRow#type_map is set accordingly.
	#
	# Raises an exception if an error occurs.
	#
	# See also #copy_data.
	#
	def put_copy_data(buffer, encoder=nil)
		# sync_put_copy_data does a non-blocking attept to flush data.
		until res=sync_put_copy_data(buffer, encoder)
			# It didn't flush immediately and allocation of more buffering memory failed.
			# Wait for all data sent by doing a blocking flush.
			res = flush
		end

		# And do a blocking flush every 100 calls.
		# This is to avoid memory bloat, when sending the data is slower than calls to put_copy_data happen.
		if (@calls_to_put_copy_data += 1) > 100
			@calls_to_put_copy_data = 0
			res = flush
		end
		res
	end
	alias async_put_copy_data put_copy_data

	# call-seq:
	#    conn.put_copy_end( [ error_message ] ) -> Boolean
	#
	# Sends end-of-data indication to the server.
	#
	# _error_message_ is an optional parameter, and if set,
	# forces the COPY command to fail with the string
	# _error_message_.
	#
	# Returns true if the end-of-data was sent, #false* if it was
	# not sent (*false* is only possible if the connection
	# is in nonblocking mode, and this command would block).
	def put_copy_end(*args)
		until sync_put_copy_end(*args)
			flush
		end
		@calls_to_put_copy_data = 0
		flush
	end
	alias async_put_copy_end put_copy_end

	if method_defined? :sync_encrypt_password
		# call-seq:
		#    conn.encrypt_password( password, username, algorithm=nil ) -> String
		#
		# This function is intended to be used by client applications that wish to send commands like <tt>ALTER USER joe PASSWORD 'pwd'</tt>.
		# It is good practice not to send the original cleartext password in such a command, because it might be exposed in command logs, activity displays, and so on.
		# Instead, use this function to convert the password to encrypted form before it is sent.
		#
		# The +password+ and +username+ arguments are the cleartext password, and the SQL name of the user it is for.
		# +algorithm+ specifies the encryption algorithm to use to encrypt the password.
		# Currently supported algorithms are +md5+ and +scram-sha-256+ (+on+ and +off+ are also accepted as aliases for +md5+, for compatibility with older server versions).
		# Note that support for +scram-sha-256+ was introduced in PostgreSQL version 10, and will not work correctly with older server versions.
		# If algorithm is omitted or +nil+, this function will query the server for the current value of the +password_encryption+ setting.
		# That can block, and will fail if the current transaction is aborted, or if the connection is busy executing another query.
		# If you wish to use the default algorithm for the server but want to avoid blocking, query +password_encryption+ yourself before calling #encrypt_password, and pass that value as the algorithm.
		#
		# Return value is the encrypted password.
		# The caller can assume the string doesn't contain any special characters that would require escaping.
		#
		# Available since PostgreSQL-10.
		# See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-misc.html#LIBPQ-PQENCRYPTPASSWORDCONN].
		def encrypt_password( password, username, algorithm=nil )
			algorithm ||= exec("SHOW password_encryption").getvalue(0,0)
			sync_encrypt_password(password, username, algorithm)
		end
		alias async_encrypt_password encrypt_password
	end

	# call-seq:
	#   conn.reset()
	#
	# Resets the backend connection. This method closes the
	# backend connection and tries to re-connect.
	def reset
		reset_start
		async_connect_or_reset(:reset_poll)
		self
	end
	alias async_reset reset

	# call-seq:
	#    conn.cancel() -> String
	#
	# Requests cancellation of the command currently being
	# processed.
	#
	# Returns +nil+ on success, or a string containing the
	# error message if a failure occurs.
	def cancel
		be_pid = backend_pid
		be_key = backend_key
		cancel_request = [0x10, 1234, 5678, be_pid, be_key].pack("NnnNN")

		if Fiber.respond_to?(:scheduler) && Fiber.scheduler && RUBY_PLATFORM =~ /mingw|mswin/
			# Ruby's nonblocking IO is not really supported on Windows.
			# We work around by using threads and explicit calls to wait_readable/wait_writable.
			cl = Thread.new(socket_io.remote_address) { |ra| ra.connect }.value
			begin
				cl.write_nonblock(cancel_request)
			rescue IO::WaitReadable, Errno::EINTR
				cl.wait_writable
				retry
			end
			begin
				cl.read_nonblock(1)
			rescue IO::WaitReadable, Errno::EINTR
				cl.wait_readable
				retry
			rescue EOFError
			end
		elsif RUBY_ENGINE == 'truffleruby'
			begin
				cl = socket_io.remote_address.connect
			rescue NotImplementedError
				# Workaround for truffleruby < 21.3.0
				cl2 = Socket.for_fd(socket_io.fileno)
				cl2.autoclose = false
				adr = cl2.remote_address
				if adr.ip?
					cl = TCPSocket.new(adr.ip_address, adr.ip_port)
					cl.autoclose = false
				else
					cl = UNIXSocket.new(adr.unix_path)
					cl.autoclose = false
				end
			end
			cl.write(cancel_request)
			cl.read(1)
		else
			cl = socket_io.remote_address.connect
			# Send CANCEL_REQUEST_CODE and parameters
			cl.write(cancel_request)
			# Wait for the postmaster to close the connection, which indicates that it's processed the request.
			cl.read(1)
		end

		cl.close
		nil
	rescue SystemCallError => err
		err.to_s
	end
	alias async_cancel cancel

	private def async_connect_or_reset(poll_meth)
		# Track the progress of the connection, waiting for the socket to become readable/writable before polling it

		if (timeo = conninfo_hash[:connect_timeout].to_i) && timeo > 0
			# Lowest timeout is 2 seconds - like in libpq
			timeo = [timeo, 2].max
			host_count = conninfo_hash[:host].to_s.count(",") + 1
			stop_time = timeo * host_count + Process.clock_gettime(Process::CLOCK_MONOTONIC)
		end

		poll_status = PG::PGRES_POLLING_WRITING
		until poll_status == PG::PGRES_POLLING_OK ||
				poll_status == PG::PGRES_POLLING_FAILED

			# Set single timeout to parameter "connect_timeout" but
			# don't exceed total connection time of number-of-hosts * connect_timeout.
			timeout = [timeo, stop_time - Process.clock_gettime(Process::CLOCK_MONOTONIC)].min if stop_time
			event = if !timeout || timeout >= 0
				# If the socket needs to read, wait 'til it becomes readable to poll again
				case poll_status
				when PG::PGRES_POLLING_READING
					if defined?(IO::READABLE) # ruby-3.0+
						socket_io.wait(IO::READABLE | IO::PRIORITY, timeout)
					else
						IO.select([socket_io], nil, [socket_io], timeout)
					end

				# ...and the same for when the socket needs to write
				when PG::PGRES_POLLING_WRITING
					if defined?(IO::WRITABLE) # ruby-3.0+
						# Use wait instead of wait_readable, since connection errors are delivered as
						# exceptional/priority events on Windows.
						socket_io.wait(IO::WRITABLE | IO::PRIORITY, timeout)
					else
						# io#wait on ruby-2.x doesn't wait for priority, so fallback to IO.select
						IO.select(nil, [socket_io], [socket_io], timeout)
					end
				end
			end
			# connection to server at "localhost" (127.0.0.1), port 5433 failed: timeout expired (PG::ConnectionBad)
			# connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
			unless event
				if self.class.send(:host_is_named_pipe?, host)
					connhost = "on socket \"#{host}\""
				elsif respond_to?(:hostaddr)
					connhost = "at \"#{host}\" (#{hostaddr}), port #{port}"
				else
					connhost = "at \"#{host}\", port #{port}"
				end
				raise PG::ConnectionBad.new("connection to server #{connhost} failed: timeout expired", connection: self)
			end

			# Check to see if it's finished or failed yet
			poll_status = send( poll_meth )
		end

		unless status == PG::CONNECTION_OK
			msg = error_message
			finish
			raise PG::ConnectionBad.new(msg, connection: self)
		end

		# Set connection to nonblocking to handle all blocking states in ruby.
		# That way a fiber scheduler is able to handle IO requests.
		sync_setnonblocking(true)
		self.flush_data = true
		set_default_encoding
	end

	class << self
		# call-seq:
		#    PG::Connection.new -> conn
		#    PG::Connection.new(connection_hash) -> conn
		#    PG::Connection.new(connection_string) -> conn
		#    PG::Connection.new(host, port, options, tty, dbname, user, password) ->  conn
		#
		# Create a connection to the specified server.
		#
		# +connection_hash+ must be a ruby Hash with connection parameters.
		# See the {list of valid parameters}[https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS] in the PostgreSQL documentation.
		#
		# There are two accepted formats for +connection_string+: plain <code>keyword = value</code> strings and URIs.
		# See the documentation of {connection strings}[https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING].
		#
		# The positional parameter form has the same functionality except that the missing parameters will always take on default values. The parameters are:
		# [+host+]
		#   server hostname
		# [+port+]
		#   server port number
		# [+options+]
		#   backend options
		# [+tty+]
		#   (ignored in all versions of PostgreSQL)
		# [+dbname+]
		#   connecting database name
		# [+user+]
		#   login user name
		# [+password+]
		#   login password
		#
		# Examples:
		#
		#   # Connect using all defaults
		#   PG::Connection.new
		#
		#   # As a Hash
		#   PG::Connection.new( dbname: 'test', port: 5432 )
		#
		#   # As a String
		#   PG::Connection.new( "dbname=test port=5432" )
		#
		#   # As an Array
		#   PG::Connection.new( nil, 5432, nil, nil, 'test', nil, nil )
		#
		#   # As an URI
		#   PG::Connection.new( "postgresql://user:pass@pgsql.example.com:5432/testdb?sslmode=require" )
		#
		# If the Ruby default internal encoding is set (i.e., <code>Encoding.default_internal != nil</code>), the
		# connection will have its +client_encoding+ set accordingly.
		#
		# Raises a PG::Error if the connection fails.
		def new(*args)
			conn = connect_to_hosts(*args)

			if block_given?
				begin
					return yield conn
				ensure
					conn.finish
				end
			end
			conn
		end
		alias async_connect new
		alias connect new
		alias open new
		alias setdb new
		alias setdblogin new

		private def connect_to_hosts(*args)
			option_string = parse_connect_args(*args)
			iopts = PG::Connection.conninfo_parse(option_string).each_with_object({}){|h, o| o[h[:keyword].to_sym] = h[:val] if h[:val] }
			iopts = PG::Connection.conndefaults.each_with_object({}){|h, o| o[h[:keyword].to_sym] = h[:val] if h[:val] }.merge(iopts)

			if iopts[:hostaddr]
				# hostaddr is provided -> no need to resolve hostnames

			elsif iopts[:host] && !iopts[:host].empty? && PG.library_version >= 100000
				# Resolve DNS in Ruby to avoid blocking state while connecting.
				# Multiple comma-separated values are generated, if the hostname resolves to both IPv4 and IPv6 addresses.
				# This requires PostgreSQL-10+, so no DNS resolving is done on earlier versions.
				ihosts = iopts[:host].split(",", -1)
				iports = iopts[:port].split(",", -1)
				iports = [nil] if iports.size == 0
				iports = iports * ihosts.size if iports.size == 1
				raise PG::ConnectionBad, "could not match #{iports.size} port numbers to #{ihosts.size} hosts" if iports.size != ihosts.size

				dests = ihosts.each_with_index.flat_map do |mhost, idx|
					unless host_is_named_pipe?(mhost)
						if Fiber.respond_to?(:scheduler) &&
									Fiber.scheduler &&
									RUBY_VERSION < '3.1.'

							# Use a second thread to avoid blocking of the scheduler.
							# `TCPSocket.gethostbyname` isn't fiber aware before ruby-3.1.
							hostaddrs = Thread.new{ Addrinfo.getaddrinfo(mhost, nil, nil, :STREAM).map(&:ip_address) rescue [''] }.value
						else
							hostaddrs = Addrinfo.getaddrinfo(mhost, nil, nil, :STREAM).map(&:ip_address) rescue ['']
						end
					else
						# No hostname to resolve (UnixSocket)
						hostaddrs = [nil]
					end
					hostaddrs.map { |hostaddr| [hostaddr, mhost, iports[idx]] }
				end
				iopts.merge!(
					hostaddr: dests.map{|d| d[0] }.join(","),
					host: dests.map{|d| d[1] }.join(","),
					port: dests.map{|d| d[2] }.join(","))
			else
				# No host given
			end
			conn = self.connect_start(iopts) or
										raise(PG::Error, "Unable to create a new connection")

			raise PG::ConnectionBad, conn.error_message if conn.status == PG::CONNECTION_BAD

			conn.send(:async_connect_or_reset, :connect_poll)
			conn
		end

		private def host_is_named_pipe?(host_string)
			host_string.empty? || host_string.start_with?("/") ||  # it's UnixSocket?
							host_string.start_with?("@") ||  # it's UnixSocket in the abstract namespace?
							# it's a path on Windows?
							(RUBY_PLATFORM =~ /mingw|mswin/ && host_string =~ /\A([\/\\]|\w:[\/\\])/)
		end

		# call-seq:
		#    PG::Connection.ping(connection_hash)       -> Integer
		#    PG::Connection.ping(connection_string)     -> Integer
		#    PG::Connection.ping(host, port, options, tty, dbname, login, password) ->  Integer
		#
		# PQpingParams reports the status of the server.
		#
		# It accepts connection parameters identical to those of PQ::Connection.new .
		# It is not necessary to supply correct user name, password, or database name values to obtain the server status; however, if incorrect values are provided, the server will log a failed connection attempt.
		#
		# See PG::Connection.new for a description of the parameters.
		#
		# Returns one of:
		# [+PQPING_OK+]
		#   server is accepting connections
		# [+PQPING_REJECT+]
		#   server is alive but rejecting connections
		# [+PQPING_NO_RESPONSE+]
		#   could not establish connection
		# [+PQPING_NO_ATTEMPT+]
		#   connection not attempted (bad params)
		#
		# See also check_socket for a way to check the connection without doing any server communication.
		def ping(*args)
			if Fiber.respond_to?(:scheduler) && Fiber.scheduler
				# Run PQping in a second thread to avoid blocking of the scheduler.
				# Unfortunately there's no nonblocking way to run ping.
				Thread.new { sync_ping(*args) }.value
			else
				sync_ping(*args)
			end
		end
		alias async_ping ping

		REDIRECT_CLASS_METHODS = PG.make_shareable({
			:new => [:async_connect, :sync_connect],
			:connect => [:async_connect, :sync_connect],
			:open => [:async_connect, :sync_connect],
			:setdb => [:async_connect, :sync_connect],
			:setdblogin => [:async_connect, :sync_connect],
			:ping => [:async_ping, :sync_ping],
		})
		private_constant :REDIRECT_CLASS_METHODS

		# These methods are affected by PQsetnonblocking
		REDIRECT_SEND_METHODS = PG.make_shareable({
			:isnonblocking => [:async_isnonblocking, :sync_isnonblocking],
			:nonblocking? => [:async_isnonblocking, :sync_isnonblocking],
			:put_copy_data => [:async_put_copy_data, :sync_put_copy_data],
			:put_copy_end => [:async_put_copy_end, :sync_put_copy_end],
			:flush => [:async_flush, :sync_flush],
		})
		private_constant :REDIRECT_SEND_METHODS
		REDIRECT_METHODS = {
			:exec => [:async_exec, :sync_exec],
			:query => [:async_exec, :sync_exec],
			:exec_params => [:async_exec_params, :sync_exec_params],
			:prepare => [:async_prepare, :sync_prepare],
			:exec_prepared => [:async_exec_prepared, :sync_exec_prepared],
			:describe_portal => [:async_describe_portal, :sync_describe_portal],
			:describe_prepared => [:async_describe_prepared, :sync_describe_prepared],
			:setnonblocking => [:async_setnonblocking, :sync_setnonblocking],
			:get_result => [:async_get_result, :sync_get_result],
			:get_last_result => [:async_get_last_result, :sync_get_last_result],
			:get_copy_data => [:async_get_copy_data, :sync_get_copy_data],
			:reset => [:async_reset, :sync_reset],
			:set_client_encoding => [:async_set_client_encoding, :sync_set_client_encoding],
			:client_encoding= => [:async_set_client_encoding, :sync_set_client_encoding],
			:cancel => [:async_cancel, :sync_cancel],
		}
		private_constant :REDIRECT_METHODS

		if PG::Connection.instance_methods.include? :async_encrypt_password
			REDIRECT_METHODS.merge!({
				:encrypt_password => [:async_encrypt_password, :sync_encrypt_password],
			})
		end
		PG.make_shareable(REDIRECT_METHODS)

		def async_send_api=(enable)
			REDIRECT_SEND_METHODS.each do |ali, (async, sync)|
				undef_method(ali) if method_defined?(ali)
				alias_method( ali, enable ? async : sync )
			end
		end

		# Switch between sync and async libpq API.
		#
		#   PG::Connection.async_api = true
		# this is the default.
		# It sets an alias from #exec to #async_exec, #reset to #async_reset and so on.
		#
		#   PG::Connection.async_api = false
		# sets an alias from #exec to #sync_exec, #reset to #sync_reset and so on.
		#
		# pg-1.1.0+ defaults to libpq's async API for query related blocking methods.
		# pg-1.3.0+ defaults to libpq's async API for all possibly blocking methods.
		#
		# _PLEASE_ _NOTE_: This method is not part of the public API and is for debug and development use only.
		# Do not use this method in production code.
		# Any issues with the default setting of <tt>async_api=true</tt> should be reported to the maintainers instead.
		#
		def async_api=(enable)
			self.async_send_api = enable
			REDIRECT_METHODS.each do |ali, (async, sync)|
				remove_method(ali) if method_defined?(ali)
				alias_method( ali, enable ? async : sync )
			end
			REDIRECT_CLASS_METHODS.each do |ali, (async, sync)|
				singleton_class.remove_method(ali) if method_defined?(ali)
				singleton_class.alias_method(ali, enable ? async : sync )
			end
		end
	end

	self.async_api = true
end # class PG::Connection
