/*
 * pg_connection.c - PG::Connection class extension
 * $Id$
 *
 */

#include "pg.h"

/* Number of bytes that are reserved on the stack for query params. */
#define QUERYDATA_BUFFER_SIZE 4000


VALUE rb_cPGconn;
static ID s_id_encode;
static ID s_id_autoclose_set;
static VALUE sym_type, sym_format, sym_value;
static VALUE sym_symbol, sym_string, sym_static_symbol;

static VALUE pgconn_finish( VALUE );
static VALUE pgconn_set_default_encoding( VALUE self );
static VALUE pgconn_wait_for_flush( VALUE self );
static void pgconn_set_internal_encoding_index( VALUE );
static const rb_data_type_t pg_connection_type;
static VALUE pgconn_async_flush(VALUE self);

/*
 * Global functions
 */

/*
 * Convenience function to raise connection errors
 */
#ifdef __GNUC__
__attribute__((format(printf, 3, 4)))
#endif
static void
pg_raise_conn_error( VALUE klass, VALUE self, const char *format, ...)
{
	VALUE msg, error;
	va_list ap;

	va_start(ap, format);
	msg = rb_vsprintf(format, ap);
	va_end(ap);
	error = rb_exc_new_str(klass, msg);
	rb_iv_set(error, "@connection", self);
	rb_exc_raise(error);
}

/*
 * Fetch the PG::Connection object data pointer.
 */
t_pg_connection *
pg_get_connection( VALUE self )
{
	t_pg_connection *this;
	TypedData_Get_Struct( self, t_pg_connection, &pg_connection_type, this);

	return this;
}

/*
 * Fetch the PG::Connection object data pointer and check it's
 * PGconn data pointer for sanity.
 */
static t_pg_connection *
pg_get_connection_safe( VALUE self )
{
	t_pg_connection *this;
	TypedData_Get_Struct( self, t_pg_connection, &pg_connection_type, this);

	if ( !this->pgconn )
		pg_raise_conn_error( rb_eConnectionBad, self, "connection is closed");

	return this;
}

/*
 * Fetch the PGconn data pointer and check it for sanity.
 *
 * Note: This function is used externally by the sequel_pg gem,
 * so do changes carefully.
 *
 */
PGconn *
pg_get_pgconn( VALUE self )
{
	t_pg_connection *this;
	TypedData_Get_Struct( self, t_pg_connection, &pg_connection_type, this);

	if ( !this->pgconn ){
		pg_raise_conn_error( rb_eConnectionBad, self, "connection is closed");
	}

	return this->pgconn;
}



/*
 * Close the associated socket IO object if there is one.
 */
static void
pgconn_close_socket_io( VALUE self )
{
	t_pg_connection *this = pg_get_connection( self );
	VALUE socket_io = this->socket_io;

	if ( RTEST(socket_io) ) {
#if defined(_WIN32)
		if( rb_w32_unwrap_io_handle(this->ruby_sd) )
			pg_raise_conn_error( rb_eConnectionBad, self, "Could not unwrap win32 socket handle");
#endif
		rb_funcall( socket_io, rb_intern("close"), 0 );
	}

	RB_OBJ_WRITE(self, &this->socket_io, Qnil);
}


/*
 * Create a Ruby Array of Hashes out of a PGconninfoOptions array.
 */
static VALUE
pgconn_make_conninfo_array( const PQconninfoOption *options )
{
	VALUE ary = rb_ary_new();
	VALUE hash;
	int i = 0;

	if (!options) return Qnil;

	for(i = 0; options[i].keyword != NULL; i++) {
		hash = rb_hash_new();
		if(options[i].keyword)
			rb_hash_aset(hash, ID2SYM(rb_intern("keyword")), rb_str_new2(options[i].keyword));
		if(options[i].envvar)
			rb_hash_aset(hash, ID2SYM(rb_intern("envvar")), rb_str_new2(options[i].envvar));
		if(options[i].compiled)
			rb_hash_aset(hash, ID2SYM(rb_intern("compiled")), rb_str_new2(options[i].compiled));
		if(options[i].val)
			rb_hash_aset(hash, ID2SYM(rb_intern("val")), rb_str_new2(options[i].val));
		if(options[i].label)
			rb_hash_aset(hash, ID2SYM(rb_intern("label")), rb_str_new2(options[i].label));
		if(options[i].dispchar)
			rb_hash_aset(hash, ID2SYM(rb_intern("dispchar")), rb_str_new2(options[i].dispchar));
		rb_hash_aset(hash, ID2SYM(rb_intern("dispsize")), INT2NUM(options[i].dispsize));
		rb_ary_push(ary, hash);
	}

	return ary;
}

static const char *pg_cstr_enc(VALUE str, int enc_idx){
	const char *ptr = StringValueCStr(str);
	if( ENCODING_GET(str) == enc_idx ){
		return ptr;
	} else {
		str = rb_str_export_to_enc(str, rb_enc_from_index(enc_idx));
		return StringValueCStr(str);
	}
}


/*
 * GC Mark function
 */
static void
pgconn_gc_mark( void *_this )
{
	t_pg_connection *this = (t_pg_connection *)_this;
	rb_gc_mark_movable( this->socket_io );
	rb_gc_mark_movable( this->notice_receiver );
	rb_gc_mark_movable( this->notice_processor );
	rb_gc_mark_movable( this->type_map_for_queries );
	rb_gc_mark_movable( this->type_map_for_results );
	rb_gc_mark_movable( this->trace_stream );
	rb_gc_mark_movable( this->encoder_for_put_copy_data );
	rb_gc_mark_movable( this->decoder_for_get_copy_data );
}

static void
pgconn_gc_compact( void *_this )
{
	t_pg_connection *this = (t_pg_connection *)_this;
	pg_gc_location( this->socket_io );
	pg_gc_location( this->notice_receiver );
	pg_gc_location( this->notice_processor );
	pg_gc_location( this->type_map_for_queries );
	pg_gc_location( this->type_map_for_results );
	pg_gc_location( this->trace_stream );
	pg_gc_location( this->encoder_for_put_copy_data );
	pg_gc_location( this->decoder_for_get_copy_data );
}


/*
 * GC Free function
 */
static void
pgconn_gc_free( void *_this )
{
	t_pg_connection *this = (t_pg_connection *)_this;
#if defined(_WIN32)
	if ( RTEST(this->socket_io) ) {
		if( rb_w32_unwrap_io_handle(this->ruby_sd) ){
			rb_warn("pg: Could not unwrap win32 socket handle by garbage collector");
		}
	}
#endif
	if (this->pgconn != NULL)
		PQfinish( this->pgconn );

	xfree(this);
}

/*
 * Object Size function
 */
static size_t
pgconn_memsize( const void *_this )
{
	const t_pg_connection *this = (const t_pg_connection *)_this;
	return sizeof(*this);
}

static const rb_data_type_t pg_connection_type = {
	"PG::Connection",
	{
		pgconn_gc_mark,
		pgconn_gc_free,
		pgconn_memsize,
		pg_compact_callback(pgconn_gc_compact),
	},
	0,
	0,
	RUBY_TYPED_WB_PROTECTED,
};


/**************************************************************************
 * Class Methods
 **************************************************************************/

/*
 * Document-method: allocate
 *
 * call-seq:
 *   PG::Connection.allocate -> conn
 */
static VALUE
pgconn_s_allocate( VALUE klass )
{
	t_pg_connection *this;
	VALUE self = TypedData_Make_Struct( klass, t_pg_connection, &pg_connection_type, this );

	this->pgconn = NULL;
	RB_OBJ_WRITE(self, &this->socket_io, Qnil);
	RB_OBJ_WRITE(self, &this->notice_receiver, Qnil);
	RB_OBJ_WRITE(self, &this->notice_processor, Qnil);
	RB_OBJ_WRITE(self, &this->type_map_for_queries, pg_typemap_all_strings);
	RB_OBJ_WRITE(self, &this->type_map_for_results, pg_typemap_all_strings);
	RB_OBJ_WRITE(self, &this->encoder_for_put_copy_data, Qnil);
	RB_OBJ_WRITE(self, &this->decoder_for_get_copy_data, Qnil);
	RB_OBJ_WRITE(self, &this->trace_stream, Qnil);
	rb_ivar_set(self, rb_intern("@calls_to_put_copy_data"), INT2FIX(0));

	return self;
}

static VALUE
pgconn_s_sync_connect(int argc, VALUE *argv, VALUE klass)
{
	t_pg_connection *this;
	VALUE conninfo;
	VALUE self = pgconn_s_allocate( klass );

	this = pg_get_connection( self );
	conninfo = rb_funcall2( rb_cPGconn, rb_intern("parse_connect_args"), argc, argv );
	this->pgconn = gvl_PQconnectdb(StringValueCStr(conninfo));

	if(this->pgconn == NULL)
		rb_raise(rb_ePGerror, "PQconnectdb() unable to allocate PGconn structure");

	if (PQstatus(this->pgconn) == CONNECTION_BAD)
		pg_raise_conn_error( rb_eConnectionBad, self, "%s", PQerrorMessage(this->pgconn));

	pgconn_set_default_encoding( self );

	if (rb_block_given_p()) {
		return rb_ensure(rb_yield, self, pgconn_finish, self);
	}
	return self;
}

/*
 * call-seq:
 *    PG::Connection.connect_start(connection_hash)       -> conn
 *    PG::Connection.connect_start(connection_string)     -> conn
 *    PG::Connection.connect_start(host, port, options, tty, dbname, login, password) ->  conn
 *
 * This is an asynchronous version of PG::Connection.new.
 *
 * Use #connect_poll to poll the status of the connection.
 *
 * NOTE: this does *not* set the connection's +client_encoding+ for you if
 * +Encoding.default_internal+ is set. To set it after the connection is established,
 * call #internal_encoding=. You can also set it automatically by setting
 * <code>ENV['PGCLIENTENCODING']</code>, or include the 'options' connection parameter.
 *
 * See also the 'sample' directory of this gem and the corresponding {libpq functions}[https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PQCONNECTSTARTPARAMS].
 *
 */
static VALUE
pgconn_s_connect_start( int argc, VALUE *argv, VALUE klass )
{
	VALUE rb_conn;
	VALUE conninfo;
	t_pg_connection *this;

	/*
	 * PG::Connection.connect_start must act as both alloc() and initialize()
	 * because it is not invoked by calling new().
	 */
	rb_conn  = pgconn_s_allocate( klass );
	this = pg_get_connection( rb_conn );
	conninfo = rb_funcall2( klass, rb_intern("parse_connect_args"), argc, argv );
	this->pgconn = gvl_PQconnectStart( StringValueCStr(conninfo) );

	if( this->pgconn == NULL )
		rb_raise(rb_ePGerror, "PQconnectStart() unable to allocate PGconn structure");

	if ( PQstatus(this->pgconn) == CONNECTION_BAD )
		pg_raise_conn_error( rb_eConnectionBad, rb_conn, "%s", PQerrorMessage(this->pgconn));

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_conn, pgconn_finish, rb_conn );
	}
	return rb_conn;
}

static VALUE
pgconn_s_sync_ping( int argc, VALUE *argv, VALUE klass )
{
	PGPing ping;
	VALUE conninfo;

	conninfo = rb_funcall2( klass, rb_intern("parse_connect_args"), argc, argv );
	ping     = gvl_PQping( StringValueCStr(conninfo) );

	return INT2FIX((int)ping);
}


/*
 * Document-method: PG::Connection.conndefaults
 *
 * call-seq:
 *    PG::Connection.conndefaults() -> Array
 *
 * Returns an array of hashes. Each hash has the keys:
 * [+:keyword+]
 *   the name of the option
 * [+:envvar+]
 *   the environment variable to fall back to
 * [+:compiled+]
 *   the compiled in option as a secondary fallback
 * [+:val+]
 *   the option's current value, or +nil+ if not known
 * [+:label+]
 *   the label for the field
 * [+:dispchar+]
 *   "" for normal, "D" for debug, and "*" for password
 * [+:dispsize+]
 *   field size
 */
static VALUE
pgconn_s_conndefaults(VALUE self)
{
	PQconninfoOption *options = PQconndefaults();
	VALUE array = pgconn_make_conninfo_array( options );

	PQconninfoFree(options);

	UNUSED( self );

	return array;
}

/*
 * Document-method: PG::Connection.conninfo_parse
 *
 * call-seq:
 *    PG::Connection.conninfo_parse(conninfo_string) -> Array
 *
 * Returns parsed connection options from the provided connection string as an array of hashes.
 * Each hash has the same keys as PG::Connection.conndefaults() .
 * The values from the +conninfo_string+ are stored in the +:val+ key.
 */
static VALUE
pgconn_s_conninfo_parse(VALUE self, VALUE conninfo)
{
	VALUE array;
	char *errmsg = NULL;
	PQconninfoOption *options = PQconninfoParse(StringValueCStr(conninfo), &errmsg);
	if(errmsg){
		VALUE error = rb_str_new_cstr(errmsg);
		PQfreemem(errmsg);
		rb_raise(rb_ePGerror, "%"PRIsVALUE, error);
	}
	array = pgconn_make_conninfo_array( options );

	PQconninfoFree(options);

	UNUSED( self );

	return array;
}


#ifdef HAVE_PQENCRYPTPASSWORDCONN
static VALUE
pgconn_sync_encrypt_password(int argc, VALUE *argv, VALUE self)
{
	char *encrypted = NULL;
	VALUE rval = Qnil;
	VALUE password, username, algorithm;
	PGconn *conn = pg_get_pgconn(self);

	rb_scan_args( argc, argv, "21", &password, &username, &algorithm );

	Check_Type(password, T_STRING);
	Check_Type(username, T_STRING);

	encrypted = gvl_PQencryptPasswordConn(conn, StringValueCStr(password), StringValueCStr(username), RTEST(algorithm) ? StringValueCStr(algorithm) : NULL);
	if ( encrypted ) {
		rval = rb_str_new2( encrypted );
		PQfreemem( encrypted );
	} else {
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));
	}

	return rval;
}
#endif


/*
 * call-seq:
 *    PG::Connection.encrypt_password( password, username ) -> String
 *
 * This is an older, deprecated version of #encrypt_password.
 * The difference is that this function always uses +md5+ as the encryption algorithm.
 *
 */
static VALUE
pgconn_s_encrypt_password(VALUE self, VALUE password, VALUE username)
{
	char *encrypted = NULL;
	VALUE rval = Qnil;

	UNUSED( self );

	Check_Type(password, T_STRING);
	Check_Type(username, T_STRING);

	encrypted = PQencryptPassword(StringValueCStr(password), StringValueCStr(username));
	rval = rb_str_new2( encrypted );
	PQfreemem( encrypted );

	return rval;
}


/**************************************************************************
 * PG::Connection INSTANCE METHODS
 **************************************************************************/

/*
 * call-seq:
 *    conn.connect_poll() -> Integer
 *
 * Returns one of:
 * [+PGRES_POLLING_READING+]
 *   wait until the socket is ready to read
 * [+PGRES_POLLING_WRITING+]
 *   wait until the socket is ready to write
 * [+PGRES_POLLING_FAILED+]
 *   the asynchronous connection has failed
 * [+PGRES_POLLING_OK+]
 *   the asynchronous connection is ready
 *
 * Example:
 *   require "io/wait"
 *
 *   conn = PG::Connection.connect_start(dbname: 'mydatabase')
 *   status = conn.connect_poll
 *   while(status != PG::PGRES_POLLING_OK) do
 *     # do some work while waiting for the connection to complete
 *     if(status == PG::PGRES_POLLING_READING)
 *       unless conn.socket_io.wait_readable(10.0)
 *         raise "Asynchronous connection timed out!"
 *       end
 *     elsif(status == PG::PGRES_POLLING_WRITING)
 *       unless conn.socket_io.wait_writable(10.0)
 *         raise "Asynchronous connection timed out!"
 *       end
 *     end
 *     status = conn.connect_poll
 *   end
 *   # now conn.status == CONNECTION_OK, and connection
 *   # is ready.
 */
static VALUE
pgconn_connect_poll(VALUE self)
{
	PostgresPollingStatusType status;
	status = gvl_PQconnectPoll(pg_get_pgconn(self));

	pgconn_close_socket_io(self);

	return INT2FIX((int)status);
}

/*
 * call-seq:
 *    conn.finish
 *
 * Closes the backend connection.
 */
static VALUE
pgconn_finish( VALUE self )
{
	t_pg_connection *this = pg_get_connection_safe( self );

	pgconn_close_socket_io( self );
	PQfinish( this->pgconn );
	this->pgconn = NULL;
	return Qnil;
}


/*
 * call-seq:
 *    conn.finished?      -> boolean
 *
 * Returns +true+ if the backend connection has been closed.
 */
static VALUE
pgconn_finished_p( VALUE self )
{
	t_pg_connection *this = pg_get_connection( self );
	if ( this->pgconn ) return Qfalse;
	return Qtrue;
}


static VALUE
pgconn_sync_reset( VALUE self )
{
	pgconn_close_socket_io( self );
	gvl_PQreset( pg_get_pgconn(self) );
	return self;
}

/*
 * call-seq:
 *    conn.reset_start() -> nil
 *
 * Initiate a connection reset in a nonblocking manner.
 * This will close the current connection and attempt to
 * reconnect using the same connection parameters.
 * Use #reset_poll to check the status of the
 * connection reset.
 */
static VALUE
pgconn_reset_start(VALUE self)
{
	pgconn_close_socket_io( self );
	if(gvl_PQresetStart(pg_get_pgconn(self)) == 0)
		pg_raise_conn_error( rb_eUnableToSend, self, "reset has failed");
	return Qnil;
}

/*
 * call-seq:
 *    conn.reset_poll -> Integer
 *
 * Checks the status of a connection reset operation.
 * See #connect_start and #connect_poll for
 * usage information and return values.
 */
static VALUE
pgconn_reset_poll(VALUE self)
{
	PostgresPollingStatusType status;
	status = gvl_PQresetPoll(pg_get_pgconn(self));

	pgconn_close_socket_io(self);

	return INT2FIX((int)status);
}


/*
 * call-seq:
 *    conn.db()
 *
 * Returns the connected database name.
 */
static VALUE
pgconn_db(VALUE self)
{
	char *db = PQdb(pg_get_pgconn(self));
	if (!db) return Qnil;
	return rb_str_new2(db);
}

/*
 * call-seq:
 *    conn.user()
 *
 * Returns the authenticated user name.
 */
static VALUE
pgconn_user(VALUE self)
{
	char *user = PQuser(pg_get_pgconn(self));
	if (!user) return Qnil;
	return rb_str_new2(user);
}

/*
 * call-seq:
 *    conn.pass()
 *
 * Returns the authenticated password.
 */
static VALUE
pgconn_pass(VALUE self)
{
	char *user = PQpass(pg_get_pgconn(self));
	if (!user) return Qnil;
	return rb_str_new2(user);
}

/*
 * call-seq:
 *    conn.host()
 *
 * Returns the server host name of the active connection.
 * This can be a host name, an IP address, or a directory path if the connection is via Unix socket.
 * (The path case can be distinguished because it will always be an absolute path, beginning with +/+ .)
 *
 * If the connection parameters specified both host and hostaddr, then +host+ will return the host information.
 * If only hostaddr was specified, then that is returned.
 * If multiple hosts were specified in the connection parameters, +host+ returns the host actually connected to.
 *
 * If there is an error producing the host information (perhaps if the connection has not been fully established or there was an error), it returns an empty string.
 *
 * If multiple hosts were specified in the connection parameters, it is not possible to rely on the result of +host+ until the connection is established.
 * The status of the connection can be checked using the function Connection#status .
 */
static VALUE
pgconn_host(VALUE self)
{
	char *host = PQhost(pg_get_pgconn(self));
	if (!host) return Qnil;
	return rb_str_new2(host);
}

/* PQhostaddr() appeared in PostgreSQL-12 together with PQresultMemorySize() */
#if defined(HAVE_PQRESULTMEMORYSIZE)
/*
 * call-seq:
 *    conn.hostaddr()
 *
 * Returns the server IP address of the active connection.
 * This can be the address that a host name resolved to, or an IP address provided through the hostaddr parameter.
 * If there is an error producing the host information (perhaps if the connection has not been fully established or there was an error), it returns an empty string.
 *
 */
static VALUE
pgconn_hostaddr(VALUE self)
{
	char *host = PQhostaddr(pg_get_pgconn(self));
	if (!host) return Qnil;
	return rb_str_new2(host);
}
#endif

/*
 * call-seq:
 *    conn.port()
 *
 * Returns the connected server port number.
 */
static VALUE
pgconn_port(VALUE self)
{
	char* port = PQport(pg_get_pgconn(self));
	if (!port || port[0] == '\0')
		return INT2NUM(DEF_PGPORT);
	else
		return INT2NUM(atoi(port));
}

/*
 * call-seq:
 *    conn.tty()
 *
 * Obsolete function.
 */
static VALUE
pgconn_tty(VALUE self)
{
	return rb_str_new2("");
}

/*
 * call-seq:
 *    conn.options()
 *
 * Returns backend option string.
 */
static VALUE
pgconn_options(VALUE self)
{
	char *options = PQoptions(pg_get_pgconn(self));
	if (!options) return Qnil;
	return rb_str_new2(options);
}


/*
 * call-seq:
 *    conn.conninfo   -> hash
 *
 * Returns the connection options used by a live connection.
 *
 * Available since PostgreSQL-9.3
 */
static VALUE
pgconn_conninfo( VALUE self )
{
	PGconn *conn = pg_get_pgconn(self);
	PQconninfoOption *options = PQconninfo( conn );
	VALUE array = pgconn_make_conninfo_array( options );

	PQconninfoFree(options);

	return array;
}


/*
 * call-seq:
 *    conn.status()
 *
 * Returns the status of the connection, which is one:
 *   PG::Constants::CONNECTION_OK
 *   PG::Constants::CONNECTION_BAD
 *
 * ... and other constants of kind PG::Constants::CONNECTION_*
 *
 * This method returns the status of the last command from memory.
 * It doesn't do any socket access hence is not suitable to test the connectivity.
 * See check_socket for a way to verify the socket state.
 *
 * Example:
 *   PG.constants.grep(/CONNECTION_/).find{|c| PG.const_get(c) == conn.status} # => :CONNECTION_OK
 */
static VALUE
pgconn_status(VALUE self)
{
	return INT2NUM(PQstatus(pg_get_pgconn(self)));
}

/*
 * call-seq:
 *    conn.transaction_status()
 *
 * returns one of the following statuses:
 *   PQTRANS_IDLE    = 0 (connection idle)
 *   PQTRANS_ACTIVE  = 1 (command in progress)
 *   PQTRANS_INTRANS = 2 (idle, within transaction block)
 *   PQTRANS_INERROR = 3 (idle, within failed transaction)
 *   PQTRANS_UNKNOWN = 4 (cannot determine status)
 */
static VALUE
pgconn_transaction_status(VALUE self)
{
	return INT2NUM(PQtransactionStatus(pg_get_pgconn(self)));
}

/*
 * call-seq:
 *    conn.parameter_status( param_name ) -> String
 *
 * Returns the setting of parameter _param_name_, where
 * _param_name_ is one of
 * * +server_version+
 * * +server_encoding+
 * * +client_encoding+
 * * +is_superuser+
 * * +session_authorization+
 * * +DateStyle+
 * * +TimeZone+
 * * +integer_datetimes+
 * * +standard_conforming_strings+
 *
 * Returns nil if the value of the parameter is not known.
 */
static VALUE
pgconn_parameter_status(VALUE self, VALUE param_name)
{
	const char *ret = PQparameterStatus(pg_get_pgconn(self), StringValueCStr(param_name));
	if(ret == NULL)
		return Qnil;
	else
		return rb_str_new2(ret);
}

/*
 * call-seq:
 *   conn.protocol_version -> Integer
 *
 * The 3.0 protocol will normally be used when communicating with PostgreSQL 7.4
 * or later servers; pre-7.4 servers support only protocol 2.0. (Protocol 1.0 is
 * obsolete and not supported by libpq.)
 */
static VALUE
pgconn_protocol_version(VALUE self)
{
	return INT2NUM(PQprotocolVersion(pg_get_pgconn(self)));
}

/*
 * call-seq:
 *   conn.server_version -> Integer
 *
 * The number is formed by converting the major, minor, and revision
 * numbers into two-decimal-digit numbers and appending them together.
 * For example, version 7.4.2 will be returned as 70402, and version
 * 8.1 will be returned as 80100 (leading zeroes are not shown). Zero
 * is returned if the connection is bad.
 *
 */
static VALUE
pgconn_server_version(VALUE self)
{
	return INT2NUM(PQserverVersion(pg_get_pgconn(self)));
}

/*
 * call-seq:
 *    conn.error_message -> String
 *
 * Returns the error message most recently generated by an operation on the connection.
 *
 * Nearly all libpq functions will set a message for conn.error_message if they fail.
 * Note that by libpq convention, a nonempty error_message result can consist of multiple lines, and will include a trailing newline.
 */
static VALUE
pgconn_error_message(VALUE self)
{
	char *error = PQerrorMessage(pg_get_pgconn(self));
	if (!error) return Qnil;
	return rb_str_new2(error);
}

/*
 * call-seq:
 *    conn.socket() -> Integer
 *
 * This method is deprecated. Please use the more portable method #socket_io .
 *
 * Returns the socket's file descriptor for this connection.
 * <tt>IO.for_fd()</tt> can be used to build a proper IO object to the socket.
 * If you do so, you will likely also want to set <tt>autoclose=false</tt>
 * on it to prevent Ruby from closing the socket to PostgreSQL if it
 * goes out of scope. Alternatively, you can use #socket_io, which
 * creates an IO that's associated with the connection object itself,
 * and so won't go out of scope until the connection does.
 *
 * *Note:* On Windows the file descriptor is not usable,
 * since it can not be used to build a Ruby IO object.
 */
static VALUE
pgconn_socket(VALUE self)
{
	int sd;
	pg_deprecated(4, ("conn.socket is deprecated and should be replaced by conn.socket_io"));

	if( (sd = PQsocket(pg_get_pgconn(self))) < 0)
		pg_raise_conn_error( rb_eConnectionBad, self, "PQsocket() can't get socket descriptor");

	return INT2NUM(sd);
}

/*
 * call-seq:
 *    conn.socket_io() -> IO
 *
 * Fetch an IO object created from the Connection's underlying socket.
 * This object can be used per <tt>socket_io.wait_readable</tt>, <tt>socket_io.wait_writable</tt> or for <tt>IO.select</tt> to wait for events while running asynchronous API calls.
 * <tt>IO#wait_*able</tt> is is <tt>Fiber.scheduler</tt> compatible in contrast to <tt>IO.select</tt>.
 *
 * The IO object can change while the connection is established, but is memorized afterwards.
 * So be sure not to cache the IO object, but repeat calling <tt>conn.socket_io</tt> instead.
 *
 * Using this method also works on Windows in contrast to using #socket .
 * It also avoids the problem of the underlying connection being closed by Ruby when an IO created using <tt>IO.for_fd(conn.socket)</tt> goes out of scope.
 */
static VALUE
pgconn_socket_io(VALUE self)
{
	int sd;
	int ruby_sd;
	t_pg_connection *this = pg_get_connection_safe( self );
	VALUE cSocket;
	VALUE socket_io = this->socket_io;

	if ( !RTEST(socket_io) ) {
		if( (sd = PQsocket(this->pgconn)) < 0){
			pg_raise_conn_error( rb_eConnectionBad, self, "PQsocket() can't get socket descriptor");
		}

		#ifdef _WIN32
			ruby_sd = rb_w32_wrap_io_handle((HANDLE)(intptr_t)sd, O_RDWR|O_BINARY|O_NOINHERIT);
			if( ruby_sd == -1 )
				pg_raise_conn_error( rb_eConnectionBad, self, "Could not wrap win32 socket handle");

			this->ruby_sd = ruby_sd;
		#else
			ruby_sd = sd;
		#endif

		cSocket = rb_const_get(rb_cObject, rb_intern("BasicSocket"));
		socket_io = rb_funcall( cSocket, rb_intern("for_fd"), 1, INT2NUM(ruby_sd));

		/* Disable autoclose feature */
		rb_funcall( socket_io, s_id_autoclose_set, 1, Qfalse );

		RB_OBJ_WRITE(self, &this->socket_io, socket_io);
	}

	return socket_io;
}

/*
 * call-seq:
 *    conn.backend_pid() -> Integer
 *
 * Returns the process ID of the backend server
 * process for this connection.
 * Note that this is a PID on database server host.
 */
static VALUE
pgconn_backend_pid(VALUE self)
{
	return INT2NUM(PQbackendPID(pg_get_pgconn(self)));
}

typedef struct
{
	struct sockaddr_storage addr;
	socklen_t salen;
} SockAddr;

/* Copy of struct pg_cancel from libpq-int.h
 *
 * See https://github.com/postgres/postgres/blame/master/src/interfaces/libpq/libpq-int.h#L577-L586
 */
struct pg_cancel
{
	SockAddr	raddr;			/* Remote address */
	int			be_pid;			/* PID of backend --- needed for cancels */
	int			be_key;			/* key of backend --- needed for cancels */
};

/*
 * call-seq:
 *    conn.backend_key() -> Integer
 *
 * Returns the key of the backend server process for this connection.
 * This key can be used to cancel queries on the server.
 */
static VALUE
pgconn_backend_key(VALUE self)
{
	int be_key;
	struct pg_cancel *cancel;
	PGconn *conn = pg_get_pgconn(self);

	cancel = (struct pg_cancel*)PQgetCancel(conn);
	if(cancel == NULL)
		pg_raise_conn_error( rb_ePGerror, self, "Invalid connection!");

	if( cancel->be_pid != PQbackendPID(conn) )
		rb_raise(rb_ePGerror,"Unexpected binary struct layout - please file a bug report at ruby-pg!");

	be_key = cancel->be_key;

	PQfreeCancel(cancel);

	return INT2NUM(be_key);
}

/*
 * call-seq:
 *    conn.connection_needs_password() -> Boolean
 *
 * Returns +true+ if the authentication method required a
 * password, but none was available. +false+ otherwise.
 */
static VALUE
pgconn_connection_needs_password(VALUE self)
{
	return PQconnectionNeedsPassword(pg_get_pgconn(self)) ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *    conn.connection_used_password() -> Boolean
 *
 * Returns +true+ if the authentication method used
 * a caller-supplied password, +false+ otherwise.
 */
static VALUE
pgconn_connection_used_password(VALUE self)
{
	return PQconnectionUsedPassword(pg_get_pgconn(self)) ? Qtrue : Qfalse;
}


/* :TODO: get_ssl */


static VALUE pgconn_sync_exec_params( int, VALUE *, VALUE );

/*
 * call-seq:
 *    conn.sync_exec(sql) -> PG::Result
 *    conn.sync_exec(sql) {|pg_result| block }
 *
 * This function has the same behavior as #async_exec, but is implemented using the synchronous command processing API of libpq.
 * It's not recommended to use explicit sync or async variants but #exec instead, unless you have a good reason to do so.
 *
 * Both #sync_exec and #async_exec release the GVL while waiting for server response, so that concurrent threads will get executed.
 * However #async_exec has two advantages:
 *
 * 1. #async_exec can be aborted by signals (like Ctrl-C), while #exec blocks signal processing until the query is answered.
 * 2. Ruby VM gets notified about IO blocked operations and can pass them through <tt>Fiber.scheduler</tt>.
 *    So only <tt>async_*</tt> methods are compatible to event based schedulers like the async gem.
 */
static VALUE
pgconn_sync_exec(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGresult *result = NULL;
	VALUE rb_pgresult;

	/* If called with no or nil parameters, use PQexec for compatibility */
	if ( argc == 1 || (argc >= 2 && argc <= 4 && NIL_P(argv[1]) )) {
		VALUE query_str = argv[0];

		result = gvl_PQexec(this->pgconn, pg_cstr_enc(query_str, this->enc_idx));
		rb_pgresult = pg_new_result(result, self);
		pg_result_check(rb_pgresult);
		if (rb_block_given_p()) {
			return rb_ensure(rb_yield, rb_pgresult, pg_result_clear, rb_pgresult);
		}
		return rb_pgresult;
	}
	pg_deprecated(0, ("forwarding exec to exec_params is deprecated"));

	/* Otherwise, just call #exec_params instead for backward-compatibility */
	return pgconn_sync_exec_params( argc, argv, self );

}


struct linked_typecast_data {
	struct linked_typecast_data *next;
	char data[0];
};

/* This struct is allocated on the stack for all query execution functions. */
struct query_params_data {

	/*
	 * Filled by caller
	 */

	/* The character encoding index of the connection. Any strings
	 * given as query parameters are converted to this encoding.
	 */
	int enc_idx;
	/* Is the query function to execute one with types array? */
	int with_types;
	/* Array of query params from user space */
	VALUE params;
	/* The typemap given from user space */
	VALUE typemap;

	/*
	 * Filled by alloc_query_params()
	 */

	/* Wraps the pointer of allocated memory, if function parameters don't
	 * fit in the memory_pool below.
	 */
	VALUE heap_pool;

	/* Pointer to the value string pointers (either within memory_pool or heap_pool).
	 * The value strings itself are either directly within RString memory or,
	 * in case of type casted values, within memory_pool or typecast_heap_chain.
	 */
	char **values;
	/* Pointer to the param lengths (either within memory_pool or heap_pool) */
	int *lengths;
	/* Pointer to the format codes (either within memory_pool or heap_pool) */
	int *formats;
	/* Pointer to the OID types (either within memory_pool or heap_pool) */
	Oid *types;

	/* This array takes the string values for the timeframe of the query,
	 * if param value conversion is required
	 */
	VALUE gc_array;

	/* Wraps a single linked list of allocated memory chunks for type casted params.
	 * Used when the memory_pool is to small.
	 */
	VALUE typecast_heap_chain;

	/* This memory pool is used to place above query function parameters on it. */
	char memory_pool[QUERYDATA_BUFFER_SIZE];
};

static void
free_typecast_heap_chain(void *_chain_entry)
{
	struct linked_typecast_data *chain_entry = (struct linked_typecast_data *)_chain_entry;
	while(chain_entry){
		struct linked_typecast_data *next = chain_entry->next;
		xfree(chain_entry);
		chain_entry = next;
	}
}

static const rb_data_type_t pg_typecast_buffer_type = {
	"PG::Connection typecast buffer chain",
	{
		(RUBY_DATA_FUNC) NULL,
		free_typecast_heap_chain,
		(size_t (*)(const void *))NULL,
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static char *
alloc_typecast_buf( VALUE *typecast_heap_chain, int len )
{
	/* Allocate a new memory chunk from heap */
	struct linked_typecast_data *allocated =
		(struct linked_typecast_data *)xmalloc(sizeof(struct linked_typecast_data) + len);

	/* Did we already wrap a memory chain per T_DATA object? */
	if( NIL_P( *typecast_heap_chain ) ){
		/* Leave free'ing of the buffer chain to the GC, when paramsData has left the stack */
		*typecast_heap_chain = TypedData_Wrap_Struct( rb_cObject, &pg_typecast_buffer_type, allocated );
		allocated->next = NULL;
	} else {
		/* Append to the chain */
		allocated->next = RTYPEDDATA_DATA( *typecast_heap_chain );
		RTYPEDDATA_DATA( *typecast_heap_chain ) = allocated;
	}

	return &allocated->data[0];
}

static const rb_data_type_t pg_query_heap_pool_type = {
	"PG::Connection query heap pool",
	{
		(RUBY_DATA_FUNC) NULL,
		RUBY_TYPED_DEFAULT_FREE,
		(size_t (*)(const void *))NULL,
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static int
alloc_query_params(struct query_params_data *paramsData)
{
	VALUE param_value;
	t_typemap *p_typemap;
	int nParams;
	int i=0;
	t_pg_coder *conv;
	unsigned int required_pool_size;
	char *memory_pool;

	Check_Type(paramsData->params, T_ARRAY);

	p_typemap = RTYPEDDATA_DATA( paramsData->typemap );
	p_typemap->funcs.fit_to_query( paramsData->typemap, paramsData->params );

	paramsData->heap_pool = Qnil;
	paramsData->typecast_heap_chain = Qnil;
	paramsData->gc_array = Qnil;

	nParams = (int)RARRAY_LEN(paramsData->params);

	required_pool_size = nParams * (
			sizeof(char *) +
			sizeof(int) +
			sizeof(int) +
			(paramsData->with_types ? sizeof(Oid) : 0));

	if( sizeof(paramsData->memory_pool) < required_pool_size ){
		/* Allocate one combined memory pool for all possible function parameters */
		memory_pool = (char*)xmalloc( required_pool_size );
		/* Leave free'ing of the buffer to the GC, when paramsData has left the stack */
		paramsData->heap_pool = TypedData_Wrap_Struct( rb_cObject, &pg_query_heap_pool_type, memory_pool );
		required_pool_size = 0;
	}else{
		/* Use stack memory for function parameters */
		memory_pool = paramsData->memory_pool;
	}

	paramsData->values = (char **)memory_pool;
	paramsData->lengths = (int *)((char*)paramsData->values + sizeof(char *) * nParams);
	paramsData->formats = (int *)((char*)paramsData->lengths + sizeof(int) * nParams);
	paramsData->types = (Oid *)((char*)paramsData->formats + sizeof(int) * nParams);

	{
		char *typecast_buf = paramsData->memory_pool + required_pool_size;

		for ( i = 0; i < nParams; i++ ) {
			param_value = rb_ary_entry(paramsData->params, i);

			paramsData->formats[i] = 0;
			if( paramsData->with_types )
				paramsData->types[i] = 0;

			/* Let the given typemap select a coder for this param */
			conv = p_typemap->funcs.typecast_query_param(p_typemap, param_value, i);

			/* Using a coder object for the param_value? Then set it's format code and oid. */
			if( conv ){
				paramsData->formats[i] = conv->format;
				if( paramsData->with_types )
					paramsData->types[i] = conv->oid;
			} else {
					/* No coder, but got we a hash form for the query param?
					 * Then take format code and oid from there. */
				if (TYPE(param_value) == T_HASH) {
					VALUE format_value = rb_hash_aref(param_value, sym_format);
					if( !NIL_P(format_value) )
						paramsData->formats[i] = NUM2INT(format_value);
					if( paramsData->with_types ){
						VALUE type_value = rb_hash_aref(param_value, sym_type);
						if( !NIL_P(type_value) )
							paramsData->types[i] = NUM2UINT(type_value);
					}
					param_value = rb_hash_aref(param_value, sym_value);
				}
			}

			if( NIL_P(param_value) ){
				paramsData->values[i] = NULL;
				paramsData->lengths[i] = 0;
			} else {
				t_pg_coder_enc_func enc_func = pg_coder_enc_func( conv );
				VALUE intermediate;

				/* 1st pass for retiving the required memory space */
				int len = enc_func(conv, param_value, NULL, &intermediate, paramsData->enc_idx);

				if( len == -1 ){
					/* The intermediate value is a String that can be used directly. */

					/* Ensure that the String object is zero terminated as expected by libpq. */
					if( paramsData->formats[i] == 0 )
						StringValueCStr(intermediate);
					/* In case a new string object was generated, make sure it doesn't get freed by the GC */
					if( intermediate != param_value ){
						if( NIL_P(paramsData->gc_array) )
							paramsData->gc_array = rb_ary_new();
						rb_ary_push(paramsData->gc_array, intermediate);
					}
					paramsData->values[i] = RSTRING_PTR(intermediate);
					paramsData->lengths[i] = RSTRING_LENINT(intermediate);

				} else {
					/* Is the stack memory pool too small to take the type casted value? */
					if( sizeof(paramsData->memory_pool) < required_pool_size + len + 1){
						typecast_buf = alloc_typecast_buf( &paramsData->typecast_heap_chain, len + 1 );
					}

					/* 2nd pass for writing the data to prepared buffer */
					len = enc_func(conv, param_value, typecast_buf, &intermediate, paramsData->enc_idx);
					paramsData->values[i] = typecast_buf;
					if( paramsData->formats[i] == 0 ){
						/* text format strings must be zero terminated and lengths are ignored */
						typecast_buf[len] = 0;
						typecast_buf += len + 1;
						required_pool_size += len + 1;
					} else {
						paramsData->lengths[i] = len;
						typecast_buf += len;
						required_pool_size += len;
					}
				}

				RB_GC_GUARD(intermediate);
			}
		}
	}

	return nParams;
}

static void
free_query_params(struct query_params_data *paramsData)
{
	/* currently nothing to free */
}

void
pgconn_query_assign_typemap( VALUE self, struct query_params_data *paramsData )
{
	if(NIL_P(paramsData->typemap)){
		/* Use default typemap for queries. It's type is checked when assigned. */
		paramsData->typemap = pg_get_connection(self)->type_map_for_queries;
	}else{
		t_typemap *tm;
		UNUSED(tm);

		/* Check type of method param */
		TypedData_Get_Struct(paramsData->typemap, t_typemap, &pg_typemap_type, tm);
	}
}

/*
 * call-seq:
 *    conn.sync_exec_params(sql, params[, result_format[, type_map]] ) -> PG::Result
 *    conn.sync_exec_params(sql, params[, result_format[, type_map]] ) {|pg_result| block }
 *
 * This function has the same behavior as #async_exec_params, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #exec_params instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_exec_params( int argc, VALUE *argv, VALUE self )
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGresult *result = NULL;
	VALUE rb_pgresult;
	VALUE command, in_res_fmt;
	int nParams;
	int resultFormat;
	struct query_params_data paramsData = { this->enc_idx };

	/* For compatibility we accept 1 to 4 parameters */
	rb_scan_args(argc, argv, "13", &command, &paramsData.params, &in_res_fmt, &paramsData.typemap);
	paramsData.with_types = 1;

	/*
	 * For backward compatibility no or +nil+ for the second parameter
	 * is passed to #exec
	 */
	if ( NIL_P(paramsData.params) ) {
		pg_deprecated(1, ("forwarding exec_params to exec is deprecated"));
		return pgconn_sync_exec( 1, argv, self );
	}
	pgconn_query_assign_typemap( self, &paramsData );

	resultFormat = NIL_P(in_res_fmt) ? 0 : NUM2INT(in_res_fmt);
	nParams = alloc_query_params( &paramsData );

	result = gvl_PQexecParams(this->pgconn, pg_cstr_enc(command, paramsData.enc_idx), nParams, paramsData.types,
		(const char * const *)paramsData.values, paramsData.lengths, paramsData.formats, resultFormat);

	free_query_params( &paramsData );

	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);

	if (rb_block_given_p()) {
		return rb_ensure(rb_yield, rb_pgresult, pg_result_clear, rb_pgresult);
	}

	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.sync_prepare(stmt_name, sql [, param_types ] ) -> PG::Result
 *
 * This function has the same behavior as #async_prepare, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #prepare instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_prepare(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGresult *result = NULL;
	VALUE rb_pgresult;
	VALUE name, command, in_paramtypes;
	VALUE param;
	int i = 0;
	int nParams = 0;
	Oid *paramTypes = NULL;
	const char *name_cstr;
	const char *command_cstr;
	int enc_idx = this->enc_idx;

	rb_scan_args(argc, argv, "21", &name, &command, &in_paramtypes);
	name_cstr = pg_cstr_enc(name, enc_idx);
	command_cstr = pg_cstr_enc(command, enc_idx);

	if(! NIL_P(in_paramtypes)) {
		Check_Type(in_paramtypes, T_ARRAY);
		nParams = (int)RARRAY_LEN(in_paramtypes);
		paramTypes = ALLOC_N(Oid, nParams);
		for(i = 0; i < nParams; i++) {
			param = rb_ary_entry(in_paramtypes, i);
			if(param == Qnil)
				paramTypes[i] = 0;
			else
				paramTypes[i] = NUM2UINT(param);
		}
	}
	result = gvl_PQprepare(this->pgconn, name_cstr, command_cstr, nParams, paramTypes);

	xfree(paramTypes);

	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);
	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.sync_exec_prepared(statement_name [, params, result_format[, type_map]] ) -> PG::Result
 *    conn.sync_exec_prepared(statement_name [, params, result_format[, type_map]] ) {|pg_result| block }
 *
 * This function has the same behavior as #async_exec_prepared, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #exec_prepared instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_exec_prepared(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGresult *result = NULL;
	VALUE rb_pgresult;
	VALUE name, in_res_fmt;
	int nParams;
	int resultFormat;
	struct query_params_data paramsData = { this->enc_idx };

	rb_scan_args(argc, argv, "13", &name, &paramsData.params, &in_res_fmt, &paramsData.typemap);
	paramsData.with_types = 0;

	if(NIL_P(paramsData.params)) {
		paramsData.params = rb_ary_new2(0);
	}
	pgconn_query_assign_typemap( self, &paramsData );

	resultFormat = NIL_P(in_res_fmt) ? 0 : NUM2INT(in_res_fmt);
	nParams = alloc_query_params( &paramsData );

	result = gvl_PQexecPrepared(this->pgconn, pg_cstr_enc(name, paramsData.enc_idx), nParams,
		(const char * const *)paramsData.values, paramsData.lengths, paramsData.formats,
		resultFormat);

	free_query_params( &paramsData );

	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);
	if (rb_block_given_p()) {
		return rb_ensure(rb_yield, rb_pgresult,
			pg_result_clear, rb_pgresult);
	}
	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.sync_describe_prepared( statement_name ) -> PG::Result
 *
 * This function has the same behavior as #async_describe_prepared, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #describe_prepared instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_describe_prepared(VALUE self, VALUE stmt_name)
{
	PGresult *result;
	VALUE rb_pgresult;
	t_pg_connection *this = pg_get_connection_safe( self );
	const char *stmt;
	if(NIL_P(stmt_name)) {
		stmt = NULL;
	}
	else {
		stmt = pg_cstr_enc(stmt_name, this->enc_idx);
	}
	result = gvl_PQdescribePrepared(this->pgconn, stmt);
	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.sync_describe_portal( portal_name ) -> PG::Result
 *
 * This function has the same behavior as #async_describe_portal, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #describe_portal instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_describe_portal(VALUE self, VALUE stmt_name)
{
	PGresult *result;
	VALUE rb_pgresult;
	t_pg_connection *this = pg_get_connection_safe( self );
	const char *stmt;
	if(NIL_P(stmt_name)) {
		stmt = NULL;
	}
	else {
		stmt = pg_cstr_enc(stmt_name, this->enc_idx);
	}
	result = gvl_PQdescribePortal(this->pgconn, stmt);
	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.make_empty_pgresult( status ) -> PG::Result
 *
 * Constructs and empty PG::Result with status _status_.
 * _status_ may be one of:
 * * +PGRES_EMPTY_QUERY+
 * * +PGRES_COMMAND_OK+
 * * +PGRES_TUPLES_OK+
 * * +PGRES_COPY_OUT+
 * * +PGRES_COPY_IN+
 * * +PGRES_BAD_RESPONSE+
 * * +PGRES_NONFATAL_ERROR+
 * * +PGRES_FATAL_ERROR+
 * * +PGRES_COPY_BOTH+
 * * +PGRES_SINGLE_TUPLE+
 * * +PGRES_PIPELINE_SYNC+
 * * +PGRES_PIPELINE_ABORTED+
 */
static VALUE
pgconn_make_empty_pgresult(VALUE self, VALUE status)
{
	PGresult *result;
	VALUE rb_pgresult;
	PGconn *conn = pg_get_pgconn(self);
	result = PQmakeEmptyPGresult(conn, NUM2INT(status));
	rb_pgresult = pg_new_result(result, self);
	pg_result_check(rb_pgresult);
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.escape_string( str ) -> String
 *
 * Returns a SQL-safe version of the String _str_.
 * This is the preferred way to make strings safe for inclusion in
 * SQL queries.
 *
 * Consider using exec_params, which avoids the need for passing values
 * inside of SQL commands.
 *
 * Character encoding of escaped string will be equal to client encoding of connection.
 *
 * NOTE: This class version of this method can only be used safely in client
 * programs that use a single PostgreSQL connection at a time (in this case it can
 * find out what it needs to know "behind the scenes"). It might give the wrong
 * results if used in programs that use multiple database connections; use the
 * same method on the connection object in such cases.
 *
 * See also convenience functions #escape_literal and #escape_identifier which also add proper quotes around the string.
 */
static VALUE
pgconn_s_escape(VALUE self, VALUE string)
{
	size_t size;
	int error;
	VALUE result;
	int enc_idx;
	int singleton = !rb_obj_is_kind_of(self, rb_cPGconn);

	StringValueCStr(string);
	enc_idx = singleton ? ENCODING_GET(string) : pg_get_connection(self)->enc_idx;
	if( ENCODING_GET(string) != enc_idx ){
		string = rb_str_export_to_enc(string, rb_enc_from_index(enc_idx));
	}

	result = rb_str_new(NULL, RSTRING_LEN(string) * 2 + 1);
	PG_ENCODING_SET_NOCHECK(result, enc_idx);
	if( !singleton ) {
		size = PQescapeStringConn(pg_get_pgconn(self), RSTRING_PTR(result),
			RSTRING_PTR(string), RSTRING_LEN(string), &error);
		if(error)
			pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(pg_get_pgconn(self)));

	} else {
		size = PQescapeString(RSTRING_PTR(result), RSTRING_PTR(string), RSTRING_LEN(string));
	}
	rb_str_set_len(result, size);

	return result;
}

/*
 * call-seq:
 *   conn.escape_bytea( string ) -> String
 *
 * Escapes binary data for use within an SQL command with the type +bytea+.
 *
 * Certain byte values must be escaped (but all byte values may be escaped)
 * when used as part of a +bytea+ literal in an SQL statement. In general, to
 * escape a byte, it is converted into the three digit octal number equal to
 * the octet value, and preceded by two backslashes. The single quote (') and
 * backslash (\) characters have special alternative escape sequences.
 * #escape_bytea performs this operation, escaping only the minimally required
 * bytes.
 *
 * Consider using exec_params, which avoids the need for passing values inside of
 * SQL commands.
 *
 * NOTE: This class version of this method can only be used safely in client
 * programs that use a single PostgreSQL connection at a time (in this case it can
 * find out what it needs to know "behind the scenes"). It might give the wrong
 * results if used in programs that use multiple database connections; use the
 * same method on the connection object in such cases.
 */
static VALUE
pgconn_s_escape_bytea(VALUE self, VALUE str)
{
	unsigned char *from, *to;
	size_t from_len, to_len;
	VALUE ret;

	Check_Type(str, T_STRING);
	from      = (unsigned char*)RSTRING_PTR(str);
	from_len  = RSTRING_LEN(str);

	if ( rb_obj_is_kind_of(self, rb_cPGconn) ) {
		to = PQescapeByteaConn(pg_get_pgconn(self), from, from_len, &to_len);
	} else {
		to = PQescapeBytea( from, from_len, &to_len);
	}

	ret = rb_str_new((char*)to, to_len - 1);
	PQfreemem(to);
	return ret;
}


/*
 * call-seq:
 *   PG::Connection.unescape_bytea( string )
 *
 * Converts an escaped string representation of binary data into binary data --- the
 * reverse of #escape_bytea. This is needed when retrieving +bytea+ data in text format,
 * but not when retrieving it in binary format.
 *
 */
static VALUE
pgconn_s_unescape_bytea(VALUE self, VALUE str)
{
	unsigned char *from, *to;
	size_t to_len;
	VALUE ret;

	UNUSED( self );

	Check_Type(str, T_STRING);
	from = (unsigned char*)StringValueCStr(str);

	to = PQunescapeBytea(from, &to_len);

	ret = rb_str_new((char*)to, to_len);
	PQfreemem(to);
	return ret;
}

/*
 * call-seq:
 *    conn.escape_literal( str ) -> String
 *
 * Escape an arbitrary String +str+ as a literal.
 *
 * See also PG::TextEncoder::QuotedLiteral for a type cast integrated version of this function.
 */
static VALUE
pgconn_escape_literal(VALUE self, VALUE string)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	char *escaped = NULL;
	VALUE result = Qnil;
	int enc_idx = this->enc_idx;

	StringValueCStr(string);
	if( ENCODING_GET(string) != enc_idx ){
		string = rb_str_export_to_enc(string, rb_enc_from_index(enc_idx));
	}

	escaped = PQescapeLiteral(this->pgconn, RSTRING_PTR(string), RSTRING_LEN(string));
	if (escaped == NULL)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(this->pgconn));

	result = rb_str_new2(escaped);
	PQfreemem(escaped);
	PG_ENCODING_SET_NOCHECK(result, enc_idx);

	return result;
}

/*
 * call-seq:
 *    conn.escape_identifier( str ) -> String
 *
 * Escape an arbitrary String +str+ as an identifier.
 *
 * This method does the same as #quote_ident with a String argument,
 * but it doesn't support an Array argument and it makes use of libpq
 * to process the string.
 */
static VALUE
pgconn_escape_identifier(VALUE self, VALUE string)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	char *escaped = NULL;
	VALUE result = Qnil;
	int enc_idx = this->enc_idx;

	StringValueCStr(string);
	if( ENCODING_GET(string) != enc_idx ){
		string = rb_str_export_to_enc(string, rb_enc_from_index(enc_idx));
	}

	escaped = PQescapeIdentifier(this->pgconn, RSTRING_PTR(string), RSTRING_LEN(string));
	if (escaped == NULL)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(this->pgconn));

	result = rb_str_new2(escaped);
	PQfreemem(escaped);
	PG_ENCODING_SET_NOCHECK(result, enc_idx);

	return result;
}

/*
 * call-seq:
 *    conn.set_single_row_mode -> self
 *
 * To enter single-row mode, call this method immediately after a successful
 * call of send_query (or a sibling function). This mode selection is effective
 * only for the currently executing query.
 * Then call Connection#get_result repeatedly, until it returns nil.
 *
 * Each (but the last) received Result has exactly one row and a
 * Result#result_status of PGRES_SINGLE_TUPLE. The last Result has
 * zero rows and is used to indicate a successful execution of the query.
 * All of these Result objects will contain the same row description data
 * (column names, types, etc) that an ordinary Result object for the query
 * would have.
 *
 * *Caution:* While processing a query, the server may return some rows and
 * then encounter an error, causing the query to be aborted. Ordinarily, pg
 * discards any such rows and reports only the error. But in single-row mode,
 * those rows will have already been returned to the application. Hence, the
 * application will see some Result objects followed by an Error raised in get_result.
 * For proper transactional behavior, the application must be designed to discard
 * or undo whatever has been done with the previously-processed rows, if the query
 * ultimately fails.
 *
 * Example:
 *   conn.send_query( "your SQL command" )
 *   conn.set_single_row_mode
 *   loop do
 *     res = conn.get_result or break
 *     res.check
 *     res.each do |row|
 *       # do something with the received row
 *     end
 *   end
 */
static VALUE
pgconn_set_single_row_mode(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);

	rb_check_frozen(self);
	if( PQsetSingleRowMode(conn) == 0 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return self;
}

static VALUE pgconn_send_query_params(int argc, VALUE *argv, VALUE self);

/*
 * call-seq:
 *    conn.send_query(sql) -> nil
 *
 * Sends SQL query request specified by _sql_ to PostgreSQL for
 * asynchronous processing, and immediately returns.
 * On failure, it raises a PG::Error.
 *
 * For backward compatibility, if you pass more than one parameter to this method,
 * it will call #send_query_params for you. New code should explicitly use #send_query_params if
 * argument placeholders are used.
 *
 */
static VALUE
pgconn_send_query(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );

	/* If called with no or nil parameters, use PQexec for compatibility */
	if ( argc == 1 || (argc >= 2 && argc <= 4 && NIL_P(argv[1]) )) {
		if(gvl_PQsendQuery(this->pgconn, pg_cstr_enc(argv[0], this->enc_idx)) == 0)
			pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));

		pgconn_wait_for_flush( self );
		return Qnil;
	}

	pg_deprecated(2, ("forwarding async_exec to async_exec_params and send_query to send_query_params is deprecated"));

	/* If called with parameters, and optionally result_format,
	 * use PQsendQueryParams
	 */
	return pgconn_send_query_params( argc, argv, self);
}

/*
 * call-seq:
 *    conn.send_query_params(sql, params [, result_format [, type_map ]] ) -> nil
 *
 * Sends SQL query request specified by _sql_ to PostgreSQL for
 * asynchronous processing, and immediately returns.
 * On failure, it raises a PG::Error.
 *
 * +params+ is an array of the bind parameters for the SQL query.
 * Each element of the +params+ array may be either:
 *   a hash of the form:
 *     {:value  => String (value of bind parameter)
 *      :type   => Integer (oid of type of bind parameter)
 *      :format => Integer (0 for text, 1 for binary)
 *     }
 *   or, it may be a String. If it is a string, that is equivalent to the hash:
 *     { :value => <string value>, :type => 0, :format => 0 }
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query. The 0th element of the +params+ array is bound
 * to $1, the 1st element is bound to $2, etc. +nil+ is treated as +NULL+.
 *
 * If the types are not specified, they will be inferred by PostgreSQL.
 * Instead of specifying type oids, it's recommended to simply add
 * explicit casts in the query to ensure that the right type is used.
 *
 * For example: "SELECT $1::int"
 *
 * The optional +result_format+ should be 0 for text results, 1
 * for binary.
 *
 * +type_map+ can be a PG::TypeMap derivation (such as PG::BasicTypeMapForQueries).
 * This will type cast the params from various Ruby types before transmission
 * based on the encoders defined by the type map. When a type encoder is used
 * the format and oid of a given bind parameter are retrieved from the encoder
 * instead out of the hash form described above.
 *
 */
static VALUE
pgconn_send_query_params(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	int result;
	VALUE command, in_res_fmt;
	int nParams;
	int resultFormat;
	struct query_params_data paramsData = { this->enc_idx };

	rb_scan_args(argc, argv, "22", &command, &paramsData.params, &in_res_fmt, &paramsData.typemap);
	paramsData.with_types = 1;

	pgconn_query_assign_typemap( self, &paramsData );
	resultFormat = NIL_P(in_res_fmt) ? 0 : NUM2INT(in_res_fmt);
	nParams = alloc_query_params( &paramsData );

	result = gvl_PQsendQueryParams(this->pgconn, pg_cstr_enc(command, paramsData.enc_idx), nParams, paramsData.types,
		(const char * const *)paramsData.values, paramsData.lengths, paramsData.formats, resultFormat);

	free_query_params( &paramsData );

	if(result == 0)
		pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));

	pgconn_wait_for_flush( self );
	return Qnil;
}

/*
 * call-seq:
 *    conn.send_prepare( stmt_name, sql [, param_types ] ) -> nil
 *
 * Prepares statement _sql_ with name _name_ to be executed later.
 * Sends prepare command asynchronously, and returns immediately.
 * On failure, it raises a PG::Error.
 *
 * +param_types+ is an optional parameter to specify the Oids of the
 * types of the parameters.
 *
 * If the types are not specified, they will be inferred by PostgreSQL.
 * Instead of specifying type oids, it's recommended to simply add
 * explicit casts in the query to ensure that the right type is used.
 *
 * For example: "SELECT $1::int"
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query.
 */
static VALUE
pgconn_send_prepare(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	int result;
	VALUE name, command, in_paramtypes;
	VALUE param;
	int i = 0;
	int nParams = 0;
	Oid *paramTypes = NULL;
	const char *name_cstr;
	const char *command_cstr;
	int enc_idx = this->enc_idx;

	rb_scan_args(argc, argv, "21", &name, &command, &in_paramtypes);
	name_cstr = pg_cstr_enc(name, enc_idx);
	command_cstr = pg_cstr_enc(command, enc_idx);

	if(! NIL_P(in_paramtypes)) {
		Check_Type(in_paramtypes, T_ARRAY);
		nParams = (int)RARRAY_LEN(in_paramtypes);
		paramTypes = ALLOC_N(Oid, nParams);
		for(i = 0; i < nParams; i++) {
			param = rb_ary_entry(in_paramtypes, i);
			if(param == Qnil)
				paramTypes[i] = 0;
			else
				paramTypes[i] = NUM2UINT(param);
		}
	}
	result = gvl_PQsendPrepare(this->pgconn, name_cstr, command_cstr, nParams, paramTypes);

	xfree(paramTypes);

	if(result == 0) {
		pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));
	}
	pgconn_wait_for_flush( self );
	return Qnil;
}

/*
 * call-seq:
 *    conn.send_query_prepared( statement_name [, params, result_format[, type_map ]] )
 *      -> nil
 *
 * Execute prepared named statement specified by _statement_name_
 * asynchronously, and returns immediately.
 * On failure, it raises a PG::Error.
 *
 * +params+ is an array of the optional bind parameters for the
 * SQL query. Each element of the +params+ array may be either:
 *   a hash of the form:
 *     {:value  => String (value of bind parameter)
 *      :format => Integer (0 for text, 1 for binary)
 *     }
 *   or, it may be a String. If it is a string, that is equivalent to the hash:
 *     { :value => <string value>, :format => 0 }
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query. The 0th element of the +params+ array is bound
 * to $1, the 1st element is bound to $2, etc. +nil+ is treated as +NULL+.
 *
 * The optional +result_format+ should be 0 for text results, 1
 * for binary.
 *
 * +type_map+ can be a PG::TypeMap derivation (such as PG::BasicTypeMapForQueries).
 * This will type cast the params from various Ruby types before transmission
 * based on the encoders defined by the type map. When a type encoder is used
 * the format and oid of a given bind parameter are retrieved from the encoder
 * instead out of the hash form described above.
 *
 */
static VALUE
pgconn_send_query_prepared(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	int result;
	VALUE name, in_res_fmt;
	int nParams;
	int resultFormat;
	struct query_params_data paramsData = { this->enc_idx };

	rb_scan_args(argc, argv, "13", &name, &paramsData.params, &in_res_fmt, &paramsData.typemap);
	paramsData.with_types = 0;

	if(NIL_P(paramsData.params)) {
		paramsData.params = rb_ary_new2(0);
	}
	pgconn_query_assign_typemap( self, &paramsData );

	resultFormat = NIL_P(in_res_fmt) ? 0 : NUM2INT(in_res_fmt);
	nParams = alloc_query_params( &paramsData );

	result = gvl_PQsendQueryPrepared(this->pgconn, pg_cstr_enc(name, paramsData.enc_idx), nParams,
		(const char * const *)paramsData.values, paramsData.lengths, paramsData.formats,
		resultFormat);

	free_query_params( &paramsData );

	if(result == 0)
		pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));

	pgconn_wait_for_flush( self );
	return Qnil;
}

/*
 * call-seq:
 *    conn.send_describe_prepared( statement_name ) -> nil
 *
 * Asynchronously send _command_ to the server. Does not block.
 * Use in combination with +conn.get_result+.
 */
static VALUE
pgconn_send_describe_prepared(VALUE self, VALUE stmt_name)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	/* returns 0 on failure */
	if(gvl_PQsendDescribePrepared(this->pgconn, pg_cstr_enc(stmt_name, this->enc_idx)) == 0)
		pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));

	pgconn_wait_for_flush( self );
	return Qnil;
}


/*
 * call-seq:
 *    conn.send_describe_portal( portal_name ) -> nil
 *
 * Asynchronously send _command_ to the server. Does not block.
 * Use in combination with +conn.get_result+.
 */
static VALUE
pgconn_send_describe_portal(VALUE self, VALUE portal)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	/* returns 0 on failure */
	if(gvl_PQsendDescribePortal(this->pgconn, pg_cstr_enc(portal, this->enc_idx)) == 0)
		pg_raise_conn_error( rb_eUnableToSend, self, "%s", PQerrorMessage(this->pgconn));

	pgconn_wait_for_flush( self );
	return Qnil;
}


static VALUE
pgconn_sync_get_result(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	PGresult *result;
	VALUE rb_pgresult;

	result = gvl_PQgetResult(conn);
	if(result == NULL)
		return Qnil;
	rb_pgresult = pg_new_result(result, self);
	if (rb_block_given_p()) {
		return rb_ensure(rb_yield, rb_pgresult,
			pg_result_clear, rb_pgresult);
	}
	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.consume_input()
 *
 * If input is available from the server, consume it.
 * After calling +consume_input+, you can check +is_busy+
 * or *notifies* to see if the state has changed.
 */
static VALUE
pgconn_consume_input(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	/* returns 0 on error */
	if(PQconsumeInput(conn) == 0) {
		pgconn_close_socket_io(self);
		pg_raise_conn_error( rb_eConnectionBad, self, "%s", PQerrorMessage(conn));
	}

	return Qnil;
}

/*
 * call-seq:
 *    conn.is_busy() -> Boolean
 *
 * Returns +true+ if a command is busy, that is, if
 * #get_result would block. Otherwise returns +false+.
 */
static VALUE
pgconn_is_busy(VALUE self)
{
	return gvl_PQisBusy(pg_get_pgconn(self)) ? Qtrue : Qfalse;
}

static VALUE
pgconn_sync_setnonblocking(VALUE self, VALUE state)
{
	int arg;
	PGconn *conn = pg_get_pgconn(self);
	rb_check_frozen(self);
	if(state == Qtrue)
		arg = 1;
	else if (state == Qfalse)
		arg = 0;
	else
		rb_raise(rb_eArgError, "Boolean value expected");

	if(PQsetnonblocking(conn, arg) == -1)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return Qnil;
}


static VALUE
pgconn_sync_isnonblocking(VALUE self)
{
	return PQisnonblocking(pg_get_pgconn(self)) ? Qtrue : Qfalse;
}

static VALUE
pgconn_sync_flush(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	int ret = PQflush(conn);
	if(ret == -1)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return (ret) ? Qfalse : Qtrue;
}

static VALUE
pgconn_sync_cancel(VALUE self)
{
	char errbuf[256];
	PGcancel *cancel;
	VALUE retval;
	int ret;

	cancel = PQgetCancel(pg_get_pgconn(self));
	if(cancel == NULL)
		pg_raise_conn_error( rb_ePGerror, self, "Invalid connection!");

	ret = gvl_PQcancel(cancel, errbuf, sizeof(errbuf));
	if(ret == 1)
		retval = Qnil;
	else
		retval = rb_str_new2(errbuf);

	PQfreeCancel(cancel);
	return retval;
}


/*
 * call-seq:
 *    conn.notifies()
 *
 * Returns a hash of the unprocessed notifications.
 * If there is no unprocessed notifier, it returns +nil+.
 */
static VALUE
pgconn_notifies(VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGnotify *notification;
	VALUE hash;
	VALUE sym_relname, sym_be_pid, sym_extra;
	VALUE relname, be_pid, extra;

	sym_relname = ID2SYM(rb_intern("relname"));
	sym_be_pid = ID2SYM(rb_intern("be_pid"));
	sym_extra = ID2SYM(rb_intern("extra"));

	notification = gvl_PQnotifies(this->pgconn);
	if (notification == NULL) {
		return Qnil;
	}

	hash = rb_hash_new();
	relname = rb_str_new2(notification->relname);
	be_pid = INT2NUM(notification->be_pid);
	extra = rb_str_new2(notification->extra);
	PG_ENCODING_SET_NOCHECK( relname, this->enc_idx );
	PG_ENCODING_SET_NOCHECK( extra, this->enc_idx );

	rb_hash_aset(hash, sym_relname, relname);
	rb_hash_aset(hash, sym_be_pid, be_pid);
	rb_hash_aset(hash, sym_extra, extra);

	PQfreemem(notification);
	return hash;
}

#if defined(_WIN32)

/* We use a specialized implementation of rb_io_wait() on Windows.
 * This is because rb_io_wait() and rb_wait_for_single_fd() are very slow on Windows.
 */

#if defined(HAVE_RUBY_FIBER_SCHEDULER_H)
#include <ruby/fiber/scheduler.h>
#endif

typedef enum {
    PG_RUBY_IO_READABLE = RB_WAITFD_IN,
    PG_RUBY_IO_WRITABLE = RB_WAITFD_OUT,
    PG_RUBY_IO_PRIORITY = RB_WAITFD_PRI,
} pg_rb_io_event_t;

int rb_w32_wait_events( HANDLE *events, int num, DWORD timeout );

static VALUE
pg_rb_thread_io_wait(VALUE io, VALUE events, VALUE timeout) {
	rb_io_t *fptr;
	struct timeval ptimeout;

	struct timeval aborttime={0,0}, currtime, waittime;
	DWORD timeout_milisec = INFINITE;
	HANDLE hEvent = WSACreateEvent();

	long rb_events = NUM2UINT(events);
	long w32_events = 0;
	DWORD wait_ret;

	GetOpenFile((io), fptr);
	if( !NIL_P(timeout) ){
		ptimeout.tv_sec = (time_t)(NUM2DBL(timeout));
		ptimeout.tv_usec = (time_t)((NUM2DBL(timeout) - (double)ptimeout.tv_sec) * 1e6);

		gettimeofday(&currtime, NULL);
		timeradd(&currtime, &ptimeout, &aborttime);
	}

	if(rb_events & PG_RUBY_IO_READABLE) w32_events |= FD_READ | FD_ACCEPT | FD_CLOSE;
	if(rb_events & PG_RUBY_IO_WRITABLE) w32_events |= FD_WRITE | FD_CONNECT;
	if(rb_events & PG_RUBY_IO_PRIORITY) w32_events |= FD_OOB;

	for(;;) {
		if ( WSAEventSelect(_get_osfhandle(fptr->fd), hEvent, w32_events) == SOCKET_ERROR ) {
			WSACloseEvent( hEvent );
			rb_raise( rb_eConnectionBad, "WSAEventSelect socket error: %d", WSAGetLastError() );
		}

		if ( !NIL_P(timeout) ) {
			gettimeofday(&currtime, NULL);
			timersub(&aborttime, &currtime, &waittime);
			timeout_milisec = (DWORD)( waittime.tv_sec * 1e3 + waittime.tv_usec / 1e3 );
		}

		if( NIL_P(timeout) || (waittime.tv_sec >= 0 && waittime.tv_usec >= 0) ){
			/* Wait for the socket to become readable before checking again */
			wait_ret = rb_w32_wait_events( &hEvent, 1, timeout_milisec );
		} else {
			wait_ret = WAIT_TIMEOUT;
		}

		if ( wait_ret == WAIT_TIMEOUT ) {
			WSACloseEvent( hEvent );
			return UINT2NUM(0);
		} else if ( wait_ret == WAIT_OBJECT_0 ) {
			WSACloseEvent( hEvent );
			/* The event we were waiting for. */
			return UINT2NUM(rb_events);
		} else if ( wait_ret == WAIT_OBJECT_0 + 1) {
			/* This indicates interruption from timer thread, GC, exception
			 * from other threads etc... */
			rb_thread_check_ints();
		} else if ( wait_ret == WAIT_FAILED ) {
			WSACloseEvent( hEvent );
			rb_raise( rb_eConnectionBad, "Wait on socket error (WaitForMultipleObjects): %lu", GetLastError() );
		} else {
			WSACloseEvent( hEvent );
			rb_raise( rb_eConnectionBad, "Wait on socket abandoned (WaitForMultipleObjects)" );
		}
	}
}

static VALUE
pg_rb_io_wait(VALUE io, VALUE events, VALUE timeout) {
#if defined(HAVE_RUBY_FIBER_SCHEDULER_H)
	/* We don't support Fiber.scheduler on Windows ruby-3.0 because there is no fast way to check whether a scheduler is active.
	 * Fortunatelly ruby-3.1 offers a C-API for it.
	 */
	VALUE scheduler = rb_fiber_scheduler_current();

	if (!NIL_P(scheduler)) {
		return rb_io_wait(io, events, timeout);
	}
#endif
	return pg_rb_thread_io_wait(io, events, timeout);
}

#elif defined(HAVE_RB_IO_WAIT)

/* Use our own function and constants names, to avoid conflicts with truffleruby-head on its road to ruby-3.0 compatibility. */
#define pg_rb_io_wait rb_io_wait
#define PG_RUBY_IO_READABLE RUBY_IO_READABLE
#define PG_RUBY_IO_WRITABLE RUBY_IO_WRITABLE
#define PG_RUBY_IO_PRIORITY RUBY_IO_PRIORITY

#else
/* For compat with ruby < 3.0 */

typedef enum {
    PG_RUBY_IO_READABLE = RB_WAITFD_IN,
    PG_RUBY_IO_WRITABLE = RB_WAITFD_OUT,
    PG_RUBY_IO_PRIORITY = RB_WAITFD_PRI,
} pg_rb_io_event_t;

static VALUE
pg_rb_io_wait(VALUE io, VALUE events, VALUE timeout) {
	rb_io_t *fptr;
	struct timeval waittime;
	int res;

	GetOpenFile((io), fptr);
	if( !NIL_P(timeout) ){
		waittime.tv_sec = (time_t)(NUM2DBL(timeout));
		waittime.tv_usec = (time_t)((NUM2DBL(timeout) - (double)waittime.tv_sec) * 1e6);
	}
	res = rb_wait_for_single_fd(fptr->fd, NUM2UINT(events), NIL_P(timeout) ? NULL : &waittime);

	return UINT2NUM(res);
}
#endif

static void *
wait_socket_readable( VALUE self, struct timeval *ptimeout, void *(*is_readable)(PGconn *))
{
	VALUE ret;
	void *retval;
	struct timeval aborttime={0,0}, currtime, waittime;
	VALUE wait_timeout = Qnil;
	PGconn *conn = pg_get_pgconn(self);

	if ( ptimeout ) {
		gettimeofday(&currtime, NULL);
		timeradd(&currtime, ptimeout, &aborttime);
	}

	while ( !(retval=is_readable(conn)) ) {
		if ( ptimeout ) {
			gettimeofday(&currtime, NULL);
			timersub(&aborttime, &currtime, &waittime);
			wait_timeout = DBL2NUM((double)(waittime.tv_sec) + (double)(waittime.tv_usec) / 1000000.0);
		}

		/* Is the given timeout valid? */
		if( !ptimeout || (waittime.tv_sec >= 0 && waittime.tv_usec >= 0) ){
			VALUE socket_io;

			/* before we wait for data, make sure everything has been sent */
			pgconn_async_flush(self);
			if ((retval=is_readable(conn)))
				return retval;

			socket_io = pgconn_socket_io(self);
			/* Wait for the socket to become readable before checking again */
			ret = pg_rb_io_wait(socket_io, RB_INT2NUM(PG_RUBY_IO_READABLE), wait_timeout);
		} else {
			ret = Qfalse;
		}

		/* Return false if the select() timed out */
		if ( ret == Qfalse ){
			return NULL;
		}

		/* Check for connection errors (PQisBusy is true on connection errors) */
		if ( PQconsumeInput(conn) == 0 ){
			pgconn_close_socket_io(self);
			pg_raise_conn_error(rb_eConnectionBad, self, "PQconsumeInput() %s", PQerrorMessage(conn));
		}
	}

	return retval;
}

/*
 * call-seq:
 *    conn.flush() -> Boolean
 *
 * Attempts to flush any queued output data to the server.
 * Returns +true+ if data is successfully flushed, +false+
 * if not. It can only return +false+ if connection is
 * in nonblocking mode.
 * Raises PG::Error if some other failure occurred.
 */
static VALUE
pgconn_async_flush(VALUE self)
{
	while( pgconn_sync_flush(self) == Qfalse ){
		/* wait for the socket to become read- or write-ready */
		int events;
		VALUE socket_io = pgconn_socket_io(self);
		events = RB_NUM2INT(pg_rb_io_wait(socket_io, RB_INT2NUM(PG_RUBY_IO_READABLE | PG_RUBY_IO_WRITABLE), Qnil));

		if (events & PG_RUBY_IO_READABLE){
			pgconn_consume_input(self);
		}
	}
	return Qtrue;
}

static VALUE
pgconn_wait_for_flush( VALUE self ){
	if( !pg_get_connection_safe(self)->flush_data )
		return Qnil;

	return pgconn_async_flush(self);
}

static VALUE
pgconn_flush_data_set( VALUE self, VALUE enabled ){
	t_pg_connection *conn = pg_get_connection(self);
	rb_check_frozen(self);
	conn->flush_data = RTEST(enabled);
	return enabled;
}

static void *
notify_readable(PGconn *conn)
{
	return (void*)gvl_PQnotifies(conn);
}

/*
 * call-seq:
 *    conn.wait_for_notify( [ timeout ] ) { |event, pid, payload| block } -> String
 *
 * Blocks while waiting for notification(s), or until the optional
 * _timeout_ is reached, whichever comes first.  _timeout_ is
 * measured in seconds and can be fractional.
 *
 * Returns +nil+ if _timeout_ is reached, the name of the NOTIFY event otherwise.
 * If used in block form, passes the name of the NOTIFY +event+, the generating
 * +pid+ and the optional +payload+ string into the block.
 */
static VALUE
pgconn_wait_for_notify(int argc, VALUE *argv, VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	PGnotify *pnotification;
	struct timeval timeout;
	struct timeval *ptimeout = NULL;
	VALUE timeout_in = Qnil, relname = Qnil, be_pid = Qnil, extra = Qnil;
	double timeout_sec;

	rb_scan_args( argc, argv, "01", &timeout_in );

	if ( RTEST(timeout_in) ) {
		timeout_sec = NUM2DBL( timeout_in );
		timeout.tv_sec = (time_t)timeout_sec;
		timeout.tv_usec = (suseconds_t)( (timeout_sec - (long)timeout_sec) * 1e6 );
		ptimeout = &timeout;
	}

	pnotification = (PGnotify*) wait_socket_readable( self, ptimeout, notify_readable);

	/* Return nil if the select timed out */
	if ( !pnotification ) return Qnil;

	relname = rb_str_new2( pnotification->relname );
	PG_ENCODING_SET_NOCHECK( relname, this->enc_idx );
	be_pid = INT2NUM( pnotification->be_pid );
	if ( *pnotification->extra ) {
		extra = rb_str_new2( pnotification->extra );
		PG_ENCODING_SET_NOCHECK( extra, this->enc_idx );
	}
	PQfreemem( pnotification );

	if ( rb_block_given_p() )
		rb_yield_values( 3, relname, be_pid, extra );

	return relname;
}


static VALUE
pgconn_sync_put_copy_data(int argc, VALUE *argv, VALUE self)
{
	int ret;
	int len;
	t_pg_connection *this = pg_get_connection_safe( self );
	VALUE value;
	VALUE buffer = Qnil;
	VALUE encoder;
	VALUE intermediate;
	t_pg_coder *p_coder = NULL;

	rb_scan_args( argc, argv, "11", &value, &encoder );

	if( NIL_P(encoder) ){
		if( NIL_P(this->encoder_for_put_copy_data) ){
			buffer = value;
		} else {
			p_coder = RTYPEDDATA_DATA( this->encoder_for_put_copy_data );
		}
	} else {
		/* Check argument type and use argument encoder */
		TypedData_Get_Struct(encoder, t_pg_coder, &pg_coder_type, p_coder);
	}

	if( p_coder ){
		t_pg_coder_enc_func enc_func;
		int enc_idx = this->enc_idx;

		enc_func = pg_coder_enc_func( p_coder );
		len = enc_func( p_coder, value, NULL, &intermediate, enc_idx);

		if( len == -1 ){
			/* The intermediate value is a String that can be used directly. */
			buffer = intermediate;
		} else {
			buffer = rb_str_new(NULL, len);
			len = enc_func( p_coder, value, RSTRING_PTR(buffer), &intermediate, enc_idx);
			rb_str_set_len( buffer, len );
		}
	}

	Check_Type(buffer, T_STRING);

	ret = gvl_PQputCopyData(this->pgconn, RSTRING_PTR(buffer), RSTRING_LENINT(buffer));
	if(ret == -1)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(this->pgconn));

	RB_GC_GUARD(intermediate);
	RB_GC_GUARD(buffer);

	return (ret) ? Qtrue : Qfalse;
}

static VALUE
pgconn_sync_put_copy_end(int argc, VALUE *argv, VALUE self)
{
	VALUE str;
	int ret;
	const char *error_message = NULL;
	t_pg_connection *this = pg_get_connection_safe( self );

	if (rb_scan_args(argc, argv, "01", &str) == 0)
		error_message = NULL;
	else
		error_message = pg_cstr_enc(str, this->enc_idx);

	ret = gvl_PQputCopyEnd(this->pgconn, error_message);
	if(ret == -1)
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(this->pgconn));

	return (ret) ? Qtrue : Qfalse;
}

static VALUE
pgconn_sync_get_copy_data(int argc, VALUE *argv, VALUE self )
{
	VALUE async_in;
	VALUE result;
	int ret;
	char *buffer;
	VALUE decoder;
	t_pg_coder *p_coder = NULL;
	t_pg_connection *this = pg_get_connection_safe( self );

	rb_scan_args(argc, argv, "02", &async_in, &decoder);

	if( NIL_P(decoder) ){
		if( !NIL_P(this->decoder_for_get_copy_data) ){
			p_coder = RTYPEDDATA_DATA( this->decoder_for_get_copy_data );
		}
	} else {
		/* Check argument type and use argument decoder */
		TypedData_Get_Struct(decoder, t_pg_coder, &pg_coder_type, p_coder);
	}

	ret = gvl_PQgetCopyData(this->pgconn, &buffer, RTEST(async_in));
	if(ret == -2){ /* error */
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(this->pgconn));
	}
	if(ret == -1) { /* No data left */
		return Qnil;
	}
	if(ret == 0) { /* would block */
		return Qfalse;
	}

	if( p_coder ){
		t_pg_coder_dec_func dec_func = pg_coder_dec_func( p_coder, p_coder->format );
		result =  dec_func( p_coder, buffer, ret, 0, 0, this->enc_idx );
	} else {
		result = rb_str_new(buffer, ret);
	}

	PQfreemem(buffer);
	return result;
}

/*
 * call-seq:
 *    conn.set_error_verbosity( verbosity ) -> Integer
 *
 * Sets connection's verbosity to _verbosity_ and returns
 * the previous setting. Available settings are:
 *
 * * PQERRORS_TERSE
 * * PQERRORS_DEFAULT
 * * PQERRORS_VERBOSE
 * * PQERRORS_SQLSTATE
 *
 * Changing the verbosity does not affect the messages available from already-existing PG::Result objects, only subsequently-created ones.
 * (But see PG::Result#verbose_error_message if you want to print a previous error with a different verbosity.)
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-control.html#LIBPQ-PQSETERRORVERBOSITY].
 */
static VALUE
pgconn_set_error_verbosity(VALUE self, VALUE in_verbosity)
{
	PGconn *conn = pg_get_pgconn(self);
	PGVerbosity verbosity = NUM2INT(in_verbosity);
	return INT2FIX(PQsetErrorVerbosity(conn, verbosity));
}

#ifdef HAVE_PQRESULTVERBOSEERRORMESSAGE
/*
 * call-seq:
 *    conn.set_error_context_visibility( context_visibility ) -> Integer
 *
 * Sets connection's context display mode to _context_visibility_ and returns
 * the previous setting. Available settings are:
 * * PQSHOW_CONTEXT_NEVER
 * * PQSHOW_CONTEXT_ERRORS
 * * PQSHOW_CONTEXT_ALWAYS
 *
 * This mode controls whether the CONTEXT field is included in messages (unless the verbosity setting is TERSE, in which case CONTEXT is never shown).
 * The NEVER mode never includes CONTEXT, while ALWAYS always includes it if available.
 * In ERRORS mode (the default), CONTEXT fields are included only for error messages, not for notices and warnings.
 *
 * Changing this mode does not affect the messages available from already-existing PG::Result objects, only subsequently-created ones.
 * (But see PG::Result#verbose_error_message if you want to print a previous error with a different display mode.)
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-control.html#LIBPQ-PQSETERRORCONTEXTVISIBILITY].
 *
 * Available since PostgreSQL-9.6
 */
static VALUE
pgconn_set_error_context_visibility(VALUE self, VALUE in_context_visibility)
{
	PGconn *conn = pg_get_pgconn(self);
	PGContextVisibility context_visibility = NUM2INT(in_context_visibility);
	return INT2FIX(PQsetErrorContextVisibility(conn, context_visibility));
}
#endif

/*
 * call-seq:
 *    conn.trace( stream ) -> nil
 *
 * Enables tracing message passing between backend. The
 * trace message will be written to the stream _stream_,
 * which must implement a method +fileno+ that returns
 * a writable file descriptor.
 */
static VALUE
pgconn_trace(VALUE self, VALUE stream)
{
	VALUE fileno;
	FILE *new_fp;
	int old_fd, new_fd;
	VALUE new_file;
	t_pg_connection *this = pg_get_connection_safe( self );

	rb_check_frozen(self);
	if(!rb_respond_to(stream,rb_intern("fileno")))
		rb_raise(rb_eArgError, "stream does not respond to method: fileno");

	fileno = rb_funcall(stream, rb_intern("fileno"), 0);
	if(fileno == Qnil)
		rb_raise(rb_eArgError, "can't get file descriptor from stream");

	/* Duplicate the file descriptor and re-open
	 * it. Then, make it into a ruby File object
	 * and assign it to an instance variable.
	 * This prevents a problem when the File
	 * object passed to this function is closed
	 * before the connection object is. */
	old_fd = NUM2INT(fileno);
	new_fd = dup(old_fd);
	new_fp = fdopen(new_fd, "w");

	if(new_fp == NULL)
		rb_raise(rb_eArgError, "stream is not writable");

	new_file = rb_funcall(rb_cIO, rb_intern("new"), 1, INT2NUM(new_fd));
	RB_OBJ_WRITE(self, &this->trace_stream, new_file);

	PQtrace(this->pgconn, new_fp);
	return Qnil;
}

/*
 * call-seq:
 *    conn.untrace() -> nil
 *
 * Disables the message tracing.
 */
static VALUE
pgconn_untrace(VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );

	PQuntrace(this->pgconn);
	rb_funcall(this->trace_stream, rb_intern("close"), 0);
	RB_OBJ_WRITE(self, &this->trace_stream, Qnil);
	return Qnil;
}


/*
 * Notice callback proxy function -- delegate the callback to the
 * currently-registered Ruby notice_receiver object.
 */
void
notice_receiver_proxy(void *arg, const PGresult *pgresult)
{
	VALUE self = (VALUE)arg;
	t_pg_connection *this = pg_get_connection( self );

	if (this->notice_receiver != Qnil) {
		VALUE result = pg_new_result_autoclear( (PGresult *)pgresult, self );

		rb_funcall(this->notice_receiver, rb_intern("call"), 1, result);
		pg_result_clear( result );
	}
	return;
}

/*
 * call-seq:
 *   conn.set_notice_receiver {|result| ... } -> Proc
 *
 * Notice and warning messages generated by the server are not returned
 * by the query execution functions, since they do not imply failure of
 * the query. Instead they are passed to a notice handling function, and
 * execution continues normally after the handler returns. The default
 * notice handling function prints the message on <tt>stderr</tt>, but the
 * application can override this behavior by supplying its own handling
 * function.
 *
 * For historical reasons, there are two levels of notice handling, called the
 * notice receiver and notice processor. The default behavior is for the notice
 * receiver to format the notice and pass a string to the notice processor for
 * printing. However, an application that chooses to provide its own notice
 * receiver will typically ignore the notice processor layer and just do all
 * the work in the notice receiver.
 *
 * This function takes a new block to act as the handler, which should
 * accept a single parameter that will be a PG::Result object, and returns
 * the Proc object previously set, or +nil+ if it was previously the default.
 *
 * If you pass no arguments, it will reset the handler to the default.
 *
 * *Note:* The +result+ passed to the block should not be used outside
 * of the block, since the corresponding C object could be freed after the
 * block finishes.
 */
static VALUE
pgconn_set_notice_receiver(VALUE self)
{
	VALUE proc, old_proc;
	t_pg_connection *this = pg_get_connection_safe( self );

	rb_check_frozen(self);
	/* If default_notice_receiver is unset, assume that the current
	 * notice receiver is the default, and save it to a global variable.
	 * This should not be a problem because the default receiver is
	 * always the same, so won't vary among connections.
	 */
	if(this->default_notice_receiver == NULL)
		this->default_notice_receiver = PQsetNoticeReceiver(this->pgconn, NULL, NULL);

	old_proc = this->notice_receiver;
	if( rb_block_given_p() ) {
		proc = rb_block_proc();
		PQsetNoticeReceiver(this->pgconn, gvl_notice_receiver_proxy, (void *)self);
	} else {
		/* if no block is given, set back to default */
		proc = Qnil;
		PQsetNoticeReceiver(this->pgconn, this->default_notice_receiver, NULL);
	}

	RB_OBJ_WRITE(self, &this->notice_receiver, proc);
	return old_proc;
}


/*
 * Notice callback proxy function -- delegate the callback to the
 * currently-registered Ruby notice_processor object.
 */
void
notice_processor_proxy(void *arg, const char *message)
{
	VALUE self = (VALUE)arg;
	t_pg_connection *this = pg_get_connection( self );

	if (this->notice_processor != Qnil) {
		VALUE message_str = rb_str_new2(message);
		PG_ENCODING_SET_NOCHECK( message_str, this->enc_idx );
		rb_funcall(this->notice_processor, rb_intern("call"), 1, message_str);
	}
	return;
}

/*
 * call-seq:
 *   conn.set_notice_processor {|message| ... } -> Proc
 *
 * See #set_notice_receiver for the description of what this and the
 * notice_processor methods do.
 *
 * This function takes a new block to act as the notice processor and returns
 * the Proc object previously set, or +nil+ if it was previously the default.
 * The block should accept a single String object.
 *
 * If you pass no arguments, it will reset the handler to the default.
 */
static VALUE
pgconn_set_notice_processor(VALUE self)
{
	VALUE proc, old_proc;
	t_pg_connection *this = pg_get_connection_safe( self );

	rb_check_frozen(self);
	/* If default_notice_processor is unset, assume that the current
	 * notice processor is the default, and save it to a global variable.
	 * This should not be a problem because the default processor is
	 * always the same, so won't vary among connections.
	 */
	if(this->default_notice_processor == NULL)
		this->default_notice_processor = PQsetNoticeProcessor(this->pgconn, NULL, NULL);

	old_proc = this->notice_processor;
	if( rb_block_given_p() ) {
		proc = rb_block_proc();
		PQsetNoticeProcessor(this->pgconn, gvl_notice_processor_proxy, (void *)self);
	} else {
		/* if no block is given, set back to default */
		proc = Qnil;
		PQsetNoticeProcessor(this->pgconn, this->default_notice_processor, NULL);
	}

	RB_OBJ_WRITE(self, &this->notice_processor, proc);
	return old_proc;
}


/*
 * call-seq:
 *    conn.get_client_encoding() -> String
 *
 * Returns the client encoding as a String.
 */
static VALUE
pgconn_get_client_encoding(VALUE self)
{
	char *encoding = (char *)pg_encoding_to_char(PQclientEncoding(pg_get_pgconn(self)));
	return rb_str_new2(encoding);
}


/*
 * call-seq:
 *    conn.sync_set_client_encoding( encoding )
 *
 * This function has the same behavior as #async_set_client_encoding, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #set_client_encoding instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_set_client_encoding(VALUE self, VALUE str)
{
	PGconn *conn = pg_get_pgconn( self );

	rb_check_frozen(self);
	Check_Type(str, T_STRING);

	if ( (gvl_PQsetClientEncoding(conn, StringValueCStr(str))) == -1 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	pgconn_set_internal_encoding_index( self );

	return Qnil;
}


/*
 * call-seq:
 *    conn.quote_ident( str ) -> String
 *    conn.quote_ident( array ) -> String
 *    PG::Connection.quote_ident( str ) -> String
 *    PG::Connection.quote_ident( array ) -> String
 *
 * Returns a string that is safe for inclusion in a SQL query as an
 * identifier. Note: this is not a quote function for values, but for
 * identifiers.
 *
 * For example, in a typical SQL query: <tt>SELECT FOO FROM MYTABLE</tt>
 * The identifier <tt>FOO</tt> is folded to lower case, so it actually
 * means <tt>foo</tt>. If you really want to access the case-sensitive
 * field name <tt>FOO</tt>, use this function like
 * <tt>conn.quote_ident('FOO')</tt>, which will return <tt>"FOO"</tt>
 * (with double-quotes). PostgreSQL will see the double-quotes, and
 * it will not fold to lower case.
 *
 * Similarly, this function also protects against special characters,
 * and other things that might allow SQL injection if the identifier
 * comes from an untrusted source.
 *
 * If the parameter is an Array, then all it's values are separately quoted
 * and then joined by a "." character. This can be used for identifiers in
 * the form "schema"."table"."column" .
 *
 * This method is functional identical to the encoder PG::TextEncoder::Identifier .
 *
 * If the instance method form is used and the input string character encoding
 * is different to the connection encoding, then the string is converted to this
 * encoding, so that the returned string is always encoded as PG::Connection#internal_encoding .
 *
 * In the singleton form (PG::Connection.quote_ident) the character encoding
 * of the result string is set to the character encoding of the input string.
 */
static VALUE
pgconn_s_quote_ident(VALUE self, VALUE str_or_array)
{
	VALUE ret;
	int enc_idx;

	if( rb_obj_is_kind_of(self, rb_cPGconn) ){
		enc_idx = pg_get_connection(self)->enc_idx;
	}else{
		enc_idx = RB_TYPE_P(str_or_array, T_STRING) ? ENCODING_GET( str_or_array ) : rb_ascii8bit_encindex();
	}
	pg_text_enc_identifier(NULL, str_or_array, NULL, &ret, enc_idx);

	return ret;
}


static void *
get_result_readable(PGconn *conn)
{
	return gvl_PQisBusy(conn) ? NULL : (void*)1;
}


/*
 * call-seq:
 *    conn.block( [ timeout ] ) -> Boolean
 *
 * Blocks until the server is no longer busy, or until the
 * optional _timeout_ is reached, whichever comes first.
 * _timeout_ is measured in seconds and can be fractional.
 *
 * Returns +false+ if _timeout_ is reached, +true+ otherwise.
 *
 * If +true+ is returned, +conn.is_busy+ will return +false+
 * and +conn.get_result+ will not block.
 */
VALUE
pgconn_block( int argc, VALUE *argv, VALUE self ) {
	struct timeval timeout;
	struct timeval *ptimeout = NULL;
	VALUE timeout_in;
	double timeout_sec;
	void *ret;

	if ( rb_scan_args(argc, argv, "01", &timeout_in) == 1 ) {
		timeout_sec = NUM2DBL( timeout_in );
		timeout.tv_sec = (time_t)timeout_sec;
		timeout.tv_usec = (suseconds_t)((timeout_sec - (long)timeout_sec) * 1e6);
		ptimeout = &timeout;
	}

	ret = wait_socket_readable( self, ptimeout, get_result_readable);

	if( !ret )
		return Qfalse;

	return Qtrue;
}


/*
 * call-seq:
 *    conn.sync_get_last_result( ) -> PG::Result
 *
 * This function has the same behavior as #async_get_last_result, but is implemented using the synchronous command processing API of libpq.
 * See #async_exec for the differences between the two API variants.
 * It's not recommended to use explicit sync or async variants but #get_last_result instead, unless you have a good reason to do so.
 */
static VALUE
pgconn_sync_get_last_result(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	VALUE rb_pgresult = Qnil;
	PGresult *cur, *prev;


	cur = prev = NULL;
	while ((cur = gvl_PQgetResult(conn)) != NULL) {
		int status;

		if (prev) PQclear(prev);
		prev = cur;

		status = PQresultStatus(cur);
		if (status == PGRES_COPY_OUT || status == PGRES_COPY_IN || status == PGRES_COPY_BOTH)
			break;
	}

	if (prev) {
		rb_pgresult = pg_new_result( prev, self );
		pg_result_check(rb_pgresult);
	}

	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.get_last_result( ) -> PG::Result
 *
 * This function retrieves all available results
 * on the current connection (from previously issued
 * asynchronous commands like +send_query()+) and
 * returns the last non-NULL result, or +nil+ if no
 * results are available.
 *
 * If the last result contains a bad result_status, an
 * appropriate exception is raised.
 *
 * This function is similar to #get_result
 * except that it is designed to get one and only
 * one result and that it checks the result state.
 */
static VALUE
pgconn_async_get_last_result(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	VALUE rb_pgresult = Qnil;
	PGresult *cur, *prev;

	cur = prev = NULL;
	for(;;) {
		int status;

		/* wait for input (without blocking) before reading each result */
		wait_socket_readable(self, NULL, get_result_readable);

		cur = gvl_PQgetResult(conn);
		if (cur == NULL)
			break;

		if (prev) PQclear(prev);
		prev = cur;

		status = PQresultStatus(cur);
		if (status == PGRES_COPY_OUT || status == PGRES_COPY_IN || status == PGRES_COPY_BOTH)
			break;
	}

	if (prev) {
		rb_pgresult = pg_new_result( prev, self );
		pg_result_check(rb_pgresult);
	}

	return rb_pgresult;
}

/*
 * call-seq:
 *    conn.discard_results()
 *
 * Silently discard any prior query result that application didn't eat.
 * This is internally used prior to Connection#exec and sibling methods.
 * It doesn't raise an exception on connection errors, but returns +false+ instead.
 *
 * Returns:
 * * +nil+  when the connection is already idle
 * * +true+  when some results have been discarded
 * * +false+  when a failure occured and the connection was closed
 *
 */
static VALUE
pgconn_discard_results(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	VALUE socket_io;

	switch( PQtransactionStatus(conn) ) {
		case PQTRANS_IDLE:
		case PQTRANS_INTRANS:
		case PQTRANS_INERROR:
			return Qnil;
		default:;
	}

	socket_io = pgconn_socket_io(self);

	for(;;) {
		PGresult *cur;
		int status;

		/* pgconn_block() raises an exception in case of errors.
		* To avoid this call pg_rb_io_wait() and PQconsumeInput() without rb_raise().
		*/
		while( gvl_PQisBusy(conn) ){
			int events;

			switch( PQflush(conn) ) {
				case 1:
					events = RB_NUM2INT(pg_rb_io_wait(socket_io, RB_INT2NUM(PG_RUBY_IO_READABLE | PG_RUBY_IO_WRITABLE), Qnil));
					if (events & PG_RUBY_IO_READABLE){
						if ( PQconsumeInput(conn) == 0 ) goto error;
					}
					break;
				case 0:
					pg_rb_io_wait(socket_io, RB_INT2NUM(PG_RUBY_IO_READABLE), Qnil);
					if ( PQconsumeInput(conn) == 0 ) goto error;
					break;
				default:
					goto error;
			}
		}

		cur = gvl_PQgetResult(conn);
		if( cur == NULL) break;

		status = PQresultStatus(cur);
		PQclear(cur);
		if (status == PGRES_COPY_IN){
			while( gvl_PQputCopyEnd(conn, "COPY terminated by new query or discard_results") == 0 ){
				pgconn_async_flush(self);
			}
		}
		if (status == PGRES_COPY_OUT){
			for(;;) {
				char *buffer = NULL;
				int st = gvl_PQgetCopyData(conn, &buffer, 1);
				if( st == 0 ) {
					/* would block -> wait for readable data */
					pg_rb_io_wait(socket_io, RB_INT2NUM(PG_RUBY_IO_READABLE), Qnil);
					if ( PQconsumeInput(conn) == 0 ) goto error;
				} else if( st > 0 ) {
					/* some data retrieved -> discard it */
					PQfreemem(buffer);
				} else {
					/* no more data */
					break;
				}
			}
		}
	}

	return Qtrue;

error:
	pgconn_close_socket_io(self);
	return Qfalse;
}

/*
 * call-seq:
 *    conn.exec(sql) -> PG::Result
 *    conn.exec(sql) {|pg_result| block }
 *
 * Sends SQL query request specified by _sql_ to PostgreSQL.
 * On success, it returns a PG::Result instance with all result rows and columns.
 * On failure, it raises a PG::Error.
 *
 * For backward compatibility, if you pass more than one parameter to this method,
 * it will call #exec_params for you. New code should explicitly use #exec_params if
 * argument placeholders are used.
 *
 * If the optional code block is given, it will be passed <i>result</i> as an argument,
 * and the PG::Result object will  automatically be cleared when the block terminates.
 * In this instance, <code>conn.exec</code> returns the value of the block.
 *
 * #exec is an alias for #async_exec which is almost identical to #sync_exec .
 * #sync_exec is implemented on the simpler synchronous command processing API of libpq, whereas
 * #async_exec is implemented on the asynchronous API and on ruby's IO mechanisms.
 * Only #async_exec is compatible to <tt>Fiber.scheduler</tt> based asynchronous IO processing introduced in ruby-3.0.
 * Both methods ensure that other threads can process while waiting for the server to
 * complete the request, but #sync_exec blocks all signals to be processed until the query is finished.
 * This is most notably visible by a delayed reaction to Control+C.
 * It's not recommended to use explicit sync or async variants but #exec instead, unless you have a good reason to do so.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQEXEC].
 */
static VALUE
pgconn_async_exec(int argc, VALUE *argv, VALUE self)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	pgconn_send_query( argc, argv, self );
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.exec_params(sql, params [, result_format [, type_map ]] ) -> nil
 *    conn.exec_params(sql, params [, result_format [, type_map ]] ) {|pg_result| block }
 *
 * Sends SQL query request specified by +sql+ to PostgreSQL using placeholders
 * for parameters.
 *
 * Returns a PG::Result instance on success. On failure, it raises a PG::Error.
 *
 * +params+ is an array of the bind parameters for the SQL query.
 * Each element of the +params+ array may be either:
 *   a hash of the form:
 *     {:value  => String (value of bind parameter)
 *      :type   => Integer (oid of type of bind parameter)
 *      :format => Integer (0 for text, 1 for binary)
 *     }
 *   or, it may be a String. If it is a string, that is equivalent to the hash:
 *     { :value => <string value>, :type => 0, :format => 0 }
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query. The 0th element of the +params+ array is bound
 * to $1, the 1st element is bound to $2, etc. +nil+ is treated as +NULL+.
 *
 * If the types are not specified, they will be inferred by PostgreSQL.
 * Instead of specifying type oids, it's recommended to simply add
 * explicit casts in the query to ensure that the right type is used.
 *
 * For example: "SELECT $1::int"
 *
 * The optional +result_format+ should be 0 for text results, 1
 * for binary.
 *
 * +type_map+ can be a PG::TypeMap derivation (such as PG::BasicTypeMapForQueries).
 * This will type cast the params from various Ruby types before transmission
 * based on the encoders defined by the type map. When a type encoder is used
 * the format and oid of a given bind parameter are retrieved from the encoder
 * instead out of the hash form described above.
 *
 * If the optional code block is given, it will be passed <i>result</i> as an argument,
 * and the PG::Result object will  automatically be cleared when the block terminates.
 * In this instance, <code>conn.exec</code> returns the value of the block.
 *
 * The primary advantage of #exec_params over #exec is that parameter values can be separated from the command string, thus avoiding the need for tedious and error-prone quoting and escaping.
 * Unlike #exec, #exec_params allows at most one SQL command in the given string.
 * (There can be semicolons in it, but not more than one nonempty command.)
 * This is a limitation of the underlying protocol, but has some usefulness as an extra defense against SQL-injection attacks.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQEXECPARAMS].
 */
static VALUE
pgconn_async_exec_params(int argc, VALUE *argv, VALUE self)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	/* If called with no or nil parameters, use PQsendQuery for compatibility */
	if ( argc == 1 || (argc >= 2 && argc <= 4 && NIL_P(argv[1]) )) {
		pg_deprecated(3, ("forwarding async_exec_params to async_exec is deprecated"));
		pgconn_send_query( argc, argv, self );
	} else {
		pgconn_send_query_params( argc, argv, self );
	}
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.prepare(stmt_name, sql [, param_types ] ) -> PG::Result
 *
 * Prepares statement _sql_ with name _name_ to be executed later.
 * Returns a PG::Result instance on success.
 * On failure, it raises a PG::Error.
 *
 * +param_types+ is an optional parameter to specify the Oids of the
 * types of the parameters.
 *
 * If the types are not specified, they will be inferred by PostgreSQL.
 * Instead of specifying type oids, it's recommended to simply add
 * explicit casts in the query to ensure that the right type is used.
 *
 * For example: "SELECT $1::int"
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQPREPARE].
 */
static VALUE
pgconn_async_prepare(int argc, VALUE *argv, VALUE self)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	pgconn_send_prepare( argc, argv, self );
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.exec_prepared(statement_name [, params, result_format[, type_map]] ) -> PG::Result
 *    conn.exec_prepared(statement_name [, params, result_format[, type_map]] ) {|pg_result| block }
 *
 * Execute prepared named statement specified by _statement_name_.
 * Returns a PG::Result instance on success.
 * On failure, it raises a PG::Error.
 *
 * +params+ is an array of the optional bind parameters for the
 * SQL query. Each element of the +params+ array may be either:
 *   a hash of the form:
 *     {:value  => String (value of bind parameter)
 *      :format => Integer (0 for text, 1 for binary)
 *     }
 *   or, it may be a String. If it is a string, that is equivalent to the hash:
 *     { :value => <string value>, :format => 0 }
 *
 * PostgreSQL bind parameters are represented as $1, $2, $3, etc.,
 * inside the SQL query. The 0th element of the +params+ array is bound
 * to $1, the 1st element is bound to $2, etc. +nil+ is treated as +NULL+.
 *
 * The optional +result_format+ should be 0 for text results, 1
 * for binary.
 *
 * +type_map+ can be a PG::TypeMap derivation (such as PG::BasicTypeMapForQueries).
 * This will type cast the params from various Ruby types before transmission
 * based on the encoders defined by the type map. When a type encoder is used
 * the format and oid of a given bind parameter are retrieved from the encoder
 * instead out of the hash form described above.
 *
 * If the optional code block is given, it will be passed <i>result</i> as an argument,
 * and the PG::Result object will  automatically be cleared when the block terminates.
 * In this instance, <code>conn.exec_prepared</code> returns the value of the block.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQEXECPREPARED].
 */
static VALUE
pgconn_async_exec_prepared(int argc, VALUE *argv, VALUE self)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	pgconn_send_query_prepared( argc, argv, self );
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.describe_portal( portal_name ) -> PG::Result
 *
 * Retrieve information about the portal _portal_name_.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQDESCRIBEPORTAL].
 */
static VALUE
pgconn_async_describe_portal(VALUE self, VALUE portal)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	pgconn_send_describe_portal( self, portal );
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


/*
 * call-seq:
 *    conn.describe_prepared( statement_name ) -> PG::Result
 *
 * Retrieve information about the prepared statement _statement_name_.
 *
 * See also corresponding {libpq function}[https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQDESCRIBEPREPARED].
 */
static VALUE
pgconn_async_describe_prepared(VALUE self, VALUE stmt_name)
{
	VALUE rb_pgresult = Qnil;

	pgconn_discard_results( self );
	pgconn_send_describe_prepared( self, stmt_name );
	rb_pgresult = pgconn_async_get_last_result( self );

	if ( rb_block_given_p() ) {
		return rb_ensure( rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
	}
	return rb_pgresult;
}


#ifdef HAVE_PQSSLATTRIBUTE
/*
 * call-seq:
 *    conn.ssl_in_use? -> Boolean
 *
 * Returns +true+ if the connection uses SSL/TLS, +false+ if not.
 *
 * Available since PostgreSQL-9.5
 */
static VALUE
pgconn_ssl_in_use(VALUE self)
{
	return PQsslInUse(pg_get_pgconn(self)) ? Qtrue : Qfalse;
}


/*
 * call-seq:
 *    conn.ssl_attribute(attribute_name) -> String
 *
 * Returns SSL-related information about the connection.
 *
 * The list of available attributes varies depending on the SSL library being used,
 * and the type of connection. If an attribute is not available, returns nil.
 *
 * The following attributes are commonly available:
 *
 * [+library+]
 *   Name of the SSL implementation in use. (Currently, only "OpenSSL" is implemented)
 * [+protocol+]
 *   SSL/TLS version in use. Common values are "SSLv2", "SSLv3", "TLSv1", "TLSv1.1" and "TLSv1.2", but an implementation may return other strings if some other protocol is used.
 * [+key_bits+]
 *   Number of key bits used by the encryption algorithm.
 * [+cipher+]
 *   A short name of the ciphersuite used, e.g. "DHE-RSA-DES-CBC3-SHA". The names are specific to each SSL implementation.
 * [+compression+]
 *   If SSL compression is in use, returns the name of the compression algorithm, or "on" if compression is used but the algorithm is not known. If compression is not in use, returns "off".
 *
 *
 * See also #ssl_attribute_names and the {corresponding libpq function}[https://www.postgresql.org/docs/current/libpq-status.html#LIBPQ-PQSSLATTRIBUTE].
 *
 * Available since PostgreSQL-9.5
 */
static VALUE
pgconn_ssl_attribute(VALUE self, VALUE attribute_name)
{
	const char *p_attr;

	p_attr = PQsslAttribute(pg_get_pgconn(self), StringValueCStr(attribute_name));
	return p_attr ? rb_str_new_cstr(p_attr) : Qnil;
}

/*
 * call-seq:
 *    conn.ssl_attribute_names -> Array<String>
 *
 * Return an array of SSL attribute names available.
 *
 * See also #ssl_attribute
 *
 * Available since PostgreSQL-9.5
 */
static VALUE
pgconn_ssl_attribute_names(VALUE self)
{
	int i;
	const char * const * p_list = PQsslAttributeNames(pg_get_pgconn(self));
	VALUE ary = rb_ary_new();

	for ( i = 0; p_list[i]; i++ ) {
		rb_ary_push( ary, rb_str_new_cstr( p_list[i] ));
	}
	return ary;
}


#endif


#ifdef HAVE_PQENTERPIPELINEMODE
/*
 * call-seq:
 *    conn.pipeline_status -> Integer
 *
 * Returns the current pipeline mode status of the libpq connection.
 *
 * PQpipelineStatus can return one of the following values:
 *
 * * PQ_PIPELINE_ON - The libpq connection is in pipeline mode.
 * * PQ_PIPELINE_OFF - The libpq connection is not in pipeline mode.
 * * PQ_PIPELINE_ABORTED - The libpq connection is in pipeline mode and an error occurred while processing the current pipeline.
 *   The aborted flag is cleared when PQgetResult returns a result of type PGRES_PIPELINE_SYNC.
 *
 * Available since PostgreSQL-14
 */
static VALUE
pgconn_pipeline_status(VALUE self)
{
	int res = PQpipelineStatus(pg_get_pgconn(self));
	return INT2FIX(res);
}


/*
 * call-seq:
 *    conn.enter_pipeline_mode -> nil
 *
 * Causes a connection to enter pipeline mode if it is currently idle or already in pipeline mode.
 *
 * Raises PG::Error and has no effect if the connection is not currently idle, i.e., it has a result ready, or it is waiting for more input from the server, etc.
 * This function does not actually send anything to the server, it just changes the libpq connection state.
 *
 * Available since PostgreSQL-14
 */
static VALUE
pgconn_enter_pipeline_mode(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	int res = PQenterPipelineMode(conn);
	if( res != 1 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return Qnil;
}

/*
 * call-seq:
 *    conn.exit_pipeline_mode -> nil
 *
 * Causes a connection to exit pipeline mode if it is currently in pipeline mode with an empty queue and no pending results.
 *
 * Takes no action if not in pipeline mode.
 * Raises PG::Error if the current statement isn't finished processing, or PQgetResult has not been called to collect results from all previously sent query.
 *
 * Available since PostgreSQL-14
 */
static VALUE
pgconn_exit_pipeline_mode(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	int res = PQexitPipelineMode(conn);
	if( res != 1 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return Qnil;
}


/*
 * call-seq:
 *    conn.pipeline_sync -> nil
 *
 * Marks a synchronization point in a pipeline by sending a sync message and flushing the send buffer.
 * This serves as the delimiter of an implicit transaction and an error recovery point; see Section 34.5.1.3 of the PostgreSQL documentation.
 *
 * Raises PG::Error if the connection is not in pipeline mode or sending a sync message failed.
 *
 * Available since PostgreSQL-14
 */
static VALUE
pgconn_pipeline_sync(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	int res = PQpipelineSync(conn);
	if( res != 1 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return Qnil;
}

/*
 * call-seq:
 *    conn.pipeline_sync -> nil
 *
 * Sends a request for the server to flush its output buffer.
 *
 * The server flushes its output buffer automatically as a result of Connection#pipeline_sync being called, or on any request when not in pipeline mode.
 * This function is useful to cause the server to flush its output buffer in pipeline mode without establishing a synchronization point.
 * Note that the request is not itself flushed to the server automatically; use Connection#flush if necessary.
 *
 * Available since PostgreSQL-14
 */
static VALUE
pgconn_send_flush_request(VALUE self)
{
	PGconn *conn = pg_get_pgconn(self);
	int res = PQsendFlushRequest(conn);
	if( res != 1 )
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));

	return Qnil;
}

#endif

/**************************************************************************
 * LARGE OBJECT SUPPORT
 **************************************************************************/

#define BLOCKING_BEGIN(conn) do { \
	int old_nonblocking = PQisnonblocking(conn); \
	PQsetnonblocking(conn, 0);

#define BLOCKING_END(th) \
	PQsetnonblocking(conn, old_nonblocking); \
} while(0);

/*
 * call-seq:
 *    conn.lo_creat( [mode] ) -> Integer
 *
 * Creates a large object with mode _mode_. Returns a large object Oid.
 * On failure, it raises PG::Error.
 */
static VALUE
pgconn_locreat(int argc, VALUE *argv, VALUE self)
{
	Oid lo_oid;
	int mode;
	VALUE nmode;
	PGconn *conn = pg_get_pgconn(self);

	if (rb_scan_args(argc, argv, "01", &nmode) == 0)
		mode = INV_READ;
	else
		mode = NUM2INT(nmode);

	BLOCKING_BEGIN(conn)
		lo_oid = lo_creat(conn, mode);
	BLOCKING_END(conn)

	if (lo_oid == 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_creat failed");

	return UINT2NUM(lo_oid);
}

/*
 * call-seq:
 *    conn.lo_create( oid ) -> Integer
 *
 * Creates a large object with oid _oid_. Returns the large object Oid.
 * On failure, it raises PG::Error.
 */
static VALUE
pgconn_locreate(VALUE self, VALUE in_lo_oid)
{
	Oid ret, lo_oid;
	PGconn *conn = pg_get_pgconn(self);
	lo_oid = NUM2UINT(in_lo_oid);

	ret = lo_create(conn, lo_oid);
	if (ret == InvalidOid)
		pg_raise_conn_error( rb_ePGerror, self, "lo_create failed");

	return UINT2NUM(ret);
}

/*
 * call-seq:
 *    conn.lo_import(file) -> Integer
 *
 * Import a file to a large object. Returns a large object Oid.
 *
 * On failure, it raises a PG::Error.
 */
static VALUE
pgconn_loimport(VALUE self, VALUE filename)
{
	Oid lo_oid;

	PGconn *conn = pg_get_pgconn(self);

	Check_Type(filename, T_STRING);

	BLOCKING_BEGIN(conn)
		lo_oid = lo_import(conn, StringValueCStr(filename));
	BLOCKING_END(conn)

	if (lo_oid == 0) {
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));
	}
	return UINT2NUM(lo_oid);
}

/*
 * call-seq:
 *    conn.lo_export( oid, file ) -> nil
 *
 * Saves a large object of _oid_ to a _file_.
 */
static VALUE
pgconn_loexport(VALUE self, VALUE lo_oid, VALUE filename)
{
	PGconn *conn = pg_get_pgconn(self);
	Oid oid;
	int ret;
	Check_Type(filename, T_STRING);

	oid = NUM2UINT(lo_oid);

	BLOCKING_BEGIN(conn)
		ret = lo_export(conn, oid, StringValueCStr(filename));
	BLOCKING_END(conn)

	if (ret < 0) {
		pg_raise_conn_error( rb_ePGerror, self, "%s", PQerrorMessage(conn));
	}
	return Qnil;
}

/*
 * call-seq:
 *    conn.lo_open( oid, [mode] ) -> Integer
 *
 * Open a large object of _oid_. Returns a large object descriptor
 * instance on success. The _mode_ argument specifies the mode for
 * the opened large object,which is either +INV_READ+, or +INV_WRITE+.
 *
 * If _mode_ is omitted, the default is +INV_READ+.
 */
static VALUE
pgconn_loopen(int argc, VALUE *argv, VALUE self)
{
	Oid lo_oid;
	int fd, mode;
	VALUE nmode, selfid;
	PGconn *conn = pg_get_pgconn(self);

	rb_scan_args(argc, argv, "11", &selfid, &nmode);
	lo_oid = NUM2UINT(selfid);
	if(NIL_P(nmode))
		mode = INV_READ;
	else
		mode = NUM2INT(nmode);

	BLOCKING_BEGIN(conn)
		fd = lo_open(conn, lo_oid, mode);
	BLOCKING_END(conn)

	if(fd < 0) {
		pg_raise_conn_error( rb_ePGerror, self, "can't open large object: %s", PQerrorMessage(conn));
	}
	return INT2FIX(fd);
}

/*
 * call-seq:
 *    conn.lo_write( lo_desc, buffer ) -> Integer
 *
 * Writes the string _buffer_ to the large object _lo_desc_.
 * Returns the number of bytes written.
 */
static VALUE
pgconn_lowrite(VALUE self, VALUE in_lo_desc, VALUE buffer)
{
	int n;
	PGconn *conn = pg_get_pgconn(self);
	int fd = NUM2INT(in_lo_desc);

	Check_Type(buffer, T_STRING);

	if( RSTRING_LEN(buffer) < 0) {
		pg_raise_conn_error( rb_ePGerror, self, "write buffer zero string");
	}
	BLOCKING_BEGIN(conn)
		n = lo_write(conn, fd, StringValuePtr(buffer),
				RSTRING_LEN(buffer));
	BLOCKING_END(conn)

	if(n < 0) {
		pg_raise_conn_error( rb_ePGerror, self, "lo_write failed: %s", PQerrorMessage(conn));
	}

	return INT2FIX(n);
}

/*
 * call-seq:
 *    conn.lo_read( lo_desc, len ) -> String
 *
 * Attempts to read _len_ bytes from large object _lo_desc_,
 * returns resulting data.
 */
static VALUE
pgconn_loread(VALUE self, VALUE in_lo_desc, VALUE in_len)
{
	int ret;
  PGconn *conn = pg_get_pgconn(self);
	int len = NUM2INT(in_len);
	int lo_desc = NUM2INT(in_lo_desc);
	VALUE str;
	char *buffer;

	if (len < 0)
		pg_raise_conn_error( rb_ePGerror, self, "negative length %d given", len);

	buffer = ALLOC_N(char, len);

	BLOCKING_BEGIN(conn)
		ret = lo_read(conn, lo_desc, buffer, len);
	BLOCKING_END(conn)

	if(ret < 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_read failed");

	if(ret == 0) {
		xfree(buffer);
		return Qnil;
	}

	str = rb_str_new(buffer, ret);
	xfree(buffer);

	return str;
}


/*
 * call-seq:
 *    conn.lo_lseek( lo_desc, offset, whence ) -> Integer
 *
 * Move the large object pointer _lo_desc_ to offset _offset_.
 * Valid values for _whence_ are +SEEK_SET+, +SEEK_CUR+, and +SEEK_END+.
 * (Or 0, 1, or 2.)
 */
static VALUE
pgconn_lolseek(VALUE self, VALUE in_lo_desc, VALUE offset, VALUE whence)
{
	PGconn *conn = pg_get_pgconn(self);
	int lo_desc = NUM2INT(in_lo_desc);
	int ret;

	BLOCKING_BEGIN(conn)
		ret = lo_lseek(conn, lo_desc, NUM2INT(offset), NUM2INT(whence));
	BLOCKING_END(conn)

	if(ret < 0) {
		pg_raise_conn_error( rb_ePGerror, self, "lo_lseek failed");
	}

	return INT2FIX(ret);
}

/*
 * call-seq:
 *    conn.lo_tell( lo_desc ) -> Integer
 *
 * Returns the current position of the large object _lo_desc_.
 */
static VALUE
pgconn_lotell(VALUE self, VALUE in_lo_desc)
{
	int position;
	PGconn *conn = pg_get_pgconn(self);
	int lo_desc = NUM2INT(in_lo_desc);

	BLOCKING_BEGIN(conn)
		position = lo_tell(conn, lo_desc);
	BLOCKING_END(conn)

	if(position < 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_tell failed");

	return INT2FIX(position);
}

/*
 * call-seq:
 *    conn.lo_truncate( lo_desc, len ) -> nil
 *
 * Truncates the large object _lo_desc_ to size _len_.
 */
static VALUE
pgconn_lotruncate(VALUE self, VALUE in_lo_desc, VALUE in_len)
{
	PGconn *conn = pg_get_pgconn(self);
	int lo_desc = NUM2INT(in_lo_desc);
	size_t len = NUM2INT(in_len);
	int ret;

	BLOCKING_BEGIN(conn)
		ret = lo_truncate(conn,lo_desc,len);
	BLOCKING_END(conn)

	if(ret < 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_truncate failed");

	return Qnil;
}

/*
 * call-seq:
 *    conn.lo_close( lo_desc ) -> nil
 *
 * Closes the postgres large object of _lo_desc_.
 */
static VALUE
pgconn_loclose(VALUE self, VALUE in_lo_desc)
{
	PGconn *conn = pg_get_pgconn(self);
	int lo_desc = NUM2INT(in_lo_desc);
	int ret;

	BLOCKING_BEGIN(conn)
		ret = lo_close(conn,lo_desc);
	BLOCKING_END(conn)

	if(ret < 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_close failed");

	return Qnil;
}

/*
 * call-seq:
 *    conn.lo_unlink( oid ) -> nil
 *
 * Unlinks (deletes) the postgres large object of _oid_.
 */
static VALUE
pgconn_lounlink(VALUE self, VALUE in_oid)
{
	PGconn *conn = pg_get_pgconn(self);
	Oid oid = NUM2UINT(in_oid);
	int ret;

	BLOCKING_BEGIN(conn)
		ret = lo_unlink(conn,oid);
	BLOCKING_END(conn)

	if(ret < 0)
		pg_raise_conn_error( rb_ePGerror, self, "lo_unlink failed");

	return Qnil;
}


static void
pgconn_set_internal_encoding_index( VALUE self )
{
	int enc_idx;
	t_pg_connection *this = pg_get_connection_safe( self );
	rb_encoding *enc = pg_conn_enc_get( this->pgconn );
	enc_idx = rb_enc_to_index(enc);
	if( enc_idx >= (1<<(PG_ENC_IDX_BITS-1)) ) rb_raise(rb_eArgError, "unsupported encoding index %d", enc_idx);
	this->enc_idx = enc_idx;
}

/*
 * call-seq:
 *   conn.internal_encoding -> Encoding
 *
 * defined in Ruby 1.9 or later.
 *
 * Returns:
 * * an Encoding - client_encoding of the connection as a Ruby Encoding object.
 * * nil - the client_encoding is 'SQL_ASCII'
 */
static VALUE
pgconn_internal_encoding(VALUE self)
{
	PGconn *conn = pg_get_pgconn( self );
	rb_encoding *enc = pg_conn_enc_get( conn );

	if ( enc ) {
		return rb_enc_from_encoding( enc );
	} else {
		return Qnil;
	}
}

static VALUE pgconn_external_encoding(VALUE self);

/*
 * call-seq:
 *   conn.internal_encoding = value
 *
 * A wrapper of #set_client_encoding.
 * defined in Ruby 1.9 or later.
 *
 * +value+ can be one of:
 * * an Encoding
 * * a String - a name of Encoding
 * * +nil+ - sets the client_encoding to SQL_ASCII.
 */
static VALUE
pgconn_internal_encoding_set(VALUE self, VALUE enc)
{
	rb_check_frozen(self);
	if (NIL_P(enc)) {
		pgconn_sync_set_client_encoding( self, rb_usascii_str_new_cstr("SQL_ASCII") );
		return enc;
	}
	else if ( TYPE(enc) == T_STRING && strcasecmp("JOHAB", StringValueCStr(enc)) == 0 ) {
		pgconn_sync_set_client_encoding(self, rb_usascii_str_new_cstr("JOHAB"));
		return enc;
	}
	else {
		rb_encoding *rbenc = rb_to_encoding( enc );
		const char *name = pg_get_rb_encoding_as_pg_encoding( rbenc );

		if ( gvl_PQsetClientEncoding(pg_get_pgconn( self ), name) == -1 ) {
			VALUE server_encoding = pgconn_external_encoding( self );
			rb_raise( rb_eEncCompatError, "incompatible character encodings: %s and %s",
					  rb_enc_name(rb_to_encoding(server_encoding)), name );
		}
		pgconn_set_internal_encoding_index( self );
		return enc;
	}
}



/*
 * call-seq:
 *   conn.external_encoding() -> Encoding
 *
 * Return the +server_encoding+ of the connected database as a Ruby Encoding object.
 * The <tt>SQL_ASCII</tt> encoding is mapped to to <tt>ASCII_8BIT</tt>.
 */
static VALUE
pgconn_external_encoding(VALUE self)
{
	t_pg_connection *this = pg_get_connection_safe( self );
	rb_encoding *enc = NULL;
	const char *pg_encname = NULL;

	pg_encname = PQparameterStatus( this->pgconn, "server_encoding" );
	enc = pg_get_pg_encname_as_rb_encoding( pg_encname );
	return rb_enc_from_encoding( enc );
}

/*
 * call-seq:
 *    conn.set_client_encoding( encoding )
 *
 * Sets the client encoding to the _encoding_ String.
 */
static VALUE
pgconn_async_set_client_encoding(VALUE self, VALUE encname)
{
	VALUE query_format, query;

	rb_check_frozen(self);
	Check_Type(encname, T_STRING);
	query_format = rb_str_new_cstr("set client_encoding to '%s'");
	query = rb_funcall(query_format, rb_intern("%"), 1, encname);

	pgconn_async_exec(1, &query, self);
	pgconn_set_internal_encoding_index( self );

	return Qnil;
}

static VALUE
pgconn_set_client_encoding_async1( VALUE args )
{
	VALUE self = ((VALUE*)args)[0];
	VALUE encname = ((VALUE*)args)[1];
	pgconn_async_set_client_encoding(self, encname);
	return 0;
}


static VALUE
pgconn_set_client_encoding_async2( VALUE arg, VALUE ex )
{
	UNUSED(arg);
	UNUSED(ex);
	return 1;
}


static VALUE
pgconn_set_client_encoding_async( VALUE self, VALUE encname )
{
	VALUE args[] = { self, encname };
	return rb_rescue(pgconn_set_client_encoding_async1, (VALUE)&args, pgconn_set_client_encoding_async2, Qnil);
}


/*
 * call-seq:
 *   conn.set_default_encoding() -> Encoding
 *
 * If Ruby has its Encoding.default_internal set, set PostgreSQL's client_encoding
 * to match. Returns the new Encoding, or +nil+ if the default internal encoding
 * wasn't set.
 */
static VALUE
pgconn_set_default_encoding( VALUE self )
{
	PGconn *conn = pg_get_pgconn( self );
	rb_encoding *enc;
	const char *encname;

	rb_check_frozen(self);
	if (( enc = rb_default_internal_encoding() )) {
		encname = pg_get_rb_encoding_as_pg_encoding( enc );
		if ( pgconn_set_client_encoding_async(self, rb_str_new_cstr(encname)) != 0 )
			rb_warning( "Failed to set the default_internal encoding to %s: '%s'",
			         encname, PQerrorMessage(conn) );
		return rb_enc_from_encoding( enc );
	} else {
		pgconn_set_internal_encoding_index( self );
		return Qnil;
	}
}


/*
 * call-seq:
 *    res.type_map_for_queries = typemap
 *
 * Set the default TypeMap that is used for type casts of query bind parameters.
 *
 * +typemap+ must be a kind of PG::TypeMap .
 *
 */
static VALUE
pgconn_type_map_for_queries_set(VALUE self, VALUE typemap)
{
	t_pg_connection *this = pg_get_connection( self );
	t_typemap *tm;
	UNUSED(tm);

	rb_check_frozen(self);
	/* Check type of method param */
	TypedData_Get_Struct(typemap, t_typemap, &pg_typemap_type, tm);

	RB_OBJ_WRITE(self, &this->type_map_for_queries, typemap);

	return typemap;
}

/*
 * call-seq:
 *    res.type_map_for_queries -> TypeMap
 *
 * Returns the default TypeMap that is currently set for type casts of query
 * bind parameters.
 *
 */
static VALUE
pgconn_type_map_for_queries_get(VALUE self)
{
	t_pg_connection *this = pg_get_connection( self );

	return this->type_map_for_queries;
}

/*
 * call-seq:
 *    res.type_map_for_results = typemap
 *
 * Set the default TypeMap that is used for type casts of result values.
 *
 * +typemap+ must be a kind of PG::TypeMap .
 *
 */
static VALUE
pgconn_type_map_for_results_set(VALUE self, VALUE typemap)
{
	t_pg_connection *this = pg_get_connection( self );
	t_typemap *tm;
	UNUSED(tm);

	rb_check_frozen(self);
	TypedData_Get_Struct(typemap, t_typemap, &pg_typemap_type, tm);
	RB_OBJ_WRITE(self, &this->type_map_for_results, typemap);

	return typemap;
}

/*
 * call-seq:
 *    res.type_map_for_results -> TypeMap
 *
 * Returns the default TypeMap that is currently set for type casts of result values.
 *
 */
static VALUE
pgconn_type_map_for_results_get(VALUE self)
{
	t_pg_connection *this = pg_get_connection( self );

	return this->type_map_for_results;
}


/*
 * call-seq:
 *    res.encoder_for_put_copy_data = encoder
 *
 * Set the default coder that is used for type casting of parameters
 * to #put_copy_data .
 *
 * +encoder+ can be:
 * * a kind of PG::Coder
 * * +nil+ - disable type encoding, data must be a String.
 *
 */
static VALUE
pgconn_encoder_for_put_copy_data_set(VALUE self, VALUE encoder)
{
	t_pg_connection *this = pg_get_connection( self );

	rb_check_frozen(self);
	if( encoder != Qnil ){
		t_pg_coder *co;
		UNUSED(co);
		/* Check argument type */
		TypedData_Get_Struct(encoder, t_pg_coder, &pg_coder_type, co);
	}
	RB_OBJ_WRITE(self, &this->encoder_for_put_copy_data, encoder);

	return encoder;
}

/*
 * call-seq:
 *    res.encoder_for_put_copy_data -> PG::Coder
 *
 * Returns the default coder object that is currently set for type casting of parameters
 * to #put_copy_data .
 *
 * Returns either:
 * * a kind of PG::Coder
 * * +nil+ - type encoding is disabled, data must be a String.
 *
 */
static VALUE
pgconn_encoder_for_put_copy_data_get(VALUE self)
{
	t_pg_connection *this = pg_get_connection( self );

	return this->encoder_for_put_copy_data;
}

/*
 * call-seq:
 *    res.decoder_for_get_copy_data = decoder
 *
 * Set the default coder that is used for type casting of received data
 * by #get_copy_data .
 *
 * +decoder+ can be:
 * * a kind of PG::Coder
 * * +nil+ - disable type decoding, returned data will be a String.
 *
 */
static VALUE
pgconn_decoder_for_get_copy_data_set(VALUE self, VALUE decoder)
{
	t_pg_connection *this = pg_get_connection( self );

	rb_check_frozen(self);
	if( decoder != Qnil ){
		t_pg_coder *co;
		UNUSED(co);
		/* Check argument type */
		TypedData_Get_Struct(decoder, t_pg_coder, &pg_coder_type, co);
	}
	RB_OBJ_WRITE(self, &this->decoder_for_get_copy_data, decoder);

	return decoder;
}

/*
 * call-seq:
 *    res.decoder_for_get_copy_data -> PG::Coder
 *
 * Returns the default coder object that is currently set for type casting of received
 * data by #get_copy_data .
 *
 * Returns either:
 * * a kind of PG::Coder
 * * +nil+ - type encoding is disabled, returned data will be a String.
 *
 */
static VALUE
pgconn_decoder_for_get_copy_data_get(VALUE self)
{
	t_pg_connection *this = pg_get_connection( self );

	return this->decoder_for_get_copy_data;
}

/*
 * call-seq:
 *    conn.field_name_type = Symbol
 *
 * Set default type of field names of results retrieved by this connection.
 * It can be set to one of:
 * * +:string+ to use String based field names
 * * +:symbol+ to use Symbol based field names
 *
 * The default is +:string+ .
 *
 * Settings the type of field names affects only future results.
 *
 * See further description at PG::Result#field_name_type=
 *
 */
static VALUE
pgconn_field_name_type_set(VALUE self, VALUE sym)
{
	t_pg_connection *this = pg_get_connection( self );

	rb_check_frozen(self);
	this->flags &= ~PG_RESULT_FIELD_NAMES_MASK;
	if( sym == sym_symbol ) this->flags |= PG_RESULT_FIELD_NAMES_SYMBOL;
	else if ( sym == sym_static_symbol ) this->flags |= PG_RESULT_FIELD_NAMES_STATIC_SYMBOL;
	else if ( sym == sym_string );
	else rb_raise(rb_eArgError, "invalid argument %+"PRIsVALUE, sym);

	return sym;
}

/*
 * call-seq:
 *    conn.field_name_type -> Symbol
 *
 * Get type of field names.
 *
 * See description at #field_name_type=
 */
static VALUE
pgconn_field_name_type_get(VALUE self)
{
	t_pg_connection *this = pg_get_connection( self );

	if( this->flags & PG_RESULT_FIELD_NAMES_SYMBOL ){
		return sym_symbol;
	} else if( this->flags & PG_RESULT_FIELD_NAMES_STATIC_SYMBOL ){
		return sym_static_symbol;
	} else {
		return sym_string;
	}
}


/*
 * Document-class: PG::Connection
 */
void
init_pg_connection(void)
{
	s_id_encode = rb_intern("encode");
	s_id_autoclose_set = rb_intern("autoclose=");
	sym_type = ID2SYM(rb_intern("type"));
	sym_format = ID2SYM(rb_intern("format"));
	sym_value = ID2SYM(rb_intern("value"));
	sym_string = ID2SYM(rb_intern("string"));
	sym_symbol = ID2SYM(rb_intern("symbol"));
	sym_static_symbol = ID2SYM(rb_intern("static_symbol"));

	rb_cPGconn = rb_define_class_under( rb_mPG, "Connection", rb_cObject );
	/* Help rdoc to known the Constants module */
	/* rb_mPGconstants = rb_define_module_under( rb_mPG, "Constants" ); */
	rb_include_module(rb_cPGconn, rb_mPGconstants);

	/******     PG::Connection CLASS METHODS     ******/
	rb_define_alloc_func( rb_cPGconn, pgconn_s_allocate );

	rb_define_singleton_method(rb_cPGconn, "escape_string", pgconn_s_escape, 1);
	SINGLETON_ALIAS(rb_cPGconn, "escape", "escape_string");
	rb_define_singleton_method(rb_cPGconn, "escape_bytea", pgconn_s_escape_bytea, 1);
	rb_define_singleton_method(rb_cPGconn, "unescape_bytea", pgconn_s_unescape_bytea, 1);
	rb_define_singleton_method(rb_cPGconn, "encrypt_password", pgconn_s_encrypt_password, 2);
	rb_define_singleton_method(rb_cPGconn, "quote_ident", pgconn_s_quote_ident, 1);
	rb_define_singleton_method(rb_cPGconn, "connect_start", pgconn_s_connect_start, -1);
	rb_define_singleton_method(rb_cPGconn, "conndefaults", pgconn_s_conndefaults, 0);
	rb_define_singleton_method(rb_cPGconn, "conninfo_parse", pgconn_s_conninfo_parse, 1);
	rb_define_singleton_method(rb_cPGconn, "sync_ping", pgconn_s_sync_ping, -1);
	rb_define_singleton_method(rb_cPGconn, "sync_connect", pgconn_s_sync_connect, -1);

	/******     PG::Connection INSTANCE METHODS: Connection Control     ******/
	rb_define_method(rb_cPGconn, "connect_poll", pgconn_connect_poll, 0);
	rb_define_method(rb_cPGconn, "finish", pgconn_finish, 0);
	rb_define_method(rb_cPGconn, "finished?", pgconn_finished_p, 0);
	rb_define_method(rb_cPGconn, "sync_reset", pgconn_sync_reset, 0);
	rb_define_method(rb_cPGconn, "reset_start", pgconn_reset_start, 0);
	rb_define_method(rb_cPGconn, "reset_poll", pgconn_reset_poll, 0);
	rb_define_alias(rb_cPGconn, "close", "finish");

	/******     PG::Connection INSTANCE METHODS: Connection Status     ******/
	rb_define_method(rb_cPGconn, "db", pgconn_db, 0);
	rb_define_method(rb_cPGconn, "user", pgconn_user, 0);
	rb_define_method(rb_cPGconn, "pass", pgconn_pass, 0);
	rb_define_method(rb_cPGconn, "host", pgconn_host, 0);
#if defined(HAVE_PQRESULTMEMORYSIZE)
	rb_define_method(rb_cPGconn, "hostaddr", pgconn_hostaddr, 0);
#endif
	rb_define_method(rb_cPGconn, "port", pgconn_port, 0);
	rb_define_method(rb_cPGconn, "tty", pgconn_tty, 0);
	rb_define_method(rb_cPGconn, "conninfo", pgconn_conninfo, 0);
	rb_define_method(rb_cPGconn, "options", pgconn_options, 0);
	rb_define_method(rb_cPGconn, "status", pgconn_status, 0);
	rb_define_method(rb_cPGconn, "transaction_status", pgconn_transaction_status, 0);
	rb_define_method(rb_cPGconn, "parameter_status", pgconn_parameter_status, 1);
	rb_define_method(rb_cPGconn, "protocol_version", pgconn_protocol_version, 0);
	rb_define_method(rb_cPGconn, "server_version", pgconn_server_version, 0);
	rb_define_method(rb_cPGconn, "error_message", pgconn_error_message, 0);
	rb_define_method(rb_cPGconn, "socket", pgconn_socket, 0);
	rb_define_method(rb_cPGconn, "socket_io", pgconn_socket_io, 0);
	rb_define_method(rb_cPGconn, "backend_pid", pgconn_backend_pid, 0);
	rb_define_method(rb_cPGconn, "backend_key", pgconn_backend_key, 0);
	rb_define_method(rb_cPGconn, "connection_needs_password", pgconn_connection_needs_password, 0);
	rb_define_method(rb_cPGconn, "connection_used_password", pgconn_connection_used_password, 0);
	/* rb_define_method(rb_cPGconn, "getssl", pgconn_getssl, 0); */

	/******     PG::Connection INSTANCE METHODS: Command Execution     ******/
	rb_define_method(rb_cPGconn, "sync_exec", pgconn_sync_exec, -1);
	rb_define_method(rb_cPGconn, "sync_exec_params", pgconn_sync_exec_params, -1);
	rb_define_method(rb_cPGconn, "sync_prepare", pgconn_sync_prepare, -1);
	rb_define_method(rb_cPGconn, "sync_exec_prepared", pgconn_sync_exec_prepared, -1);
	rb_define_method(rb_cPGconn, "sync_describe_prepared", pgconn_sync_describe_prepared, 1);
	rb_define_method(rb_cPGconn, "sync_describe_portal", pgconn_sync_describe_portal, 1);

	rb_define_method(rb_cPGconn, "exec", pgconn_async_exec, -1);
	rb_define_method(rb_cPGconn, "exec_params", pgconn_async_exec_params, -1);
	rb_define_method(rb_cPGconn, "prepare", pgconn_async_prepare, -1);
	rb_define_method(rb_cPGconn, "exec_prepared", pgconn_async_exec_prepared, -1);
	rb_define_method(rb_cPGconn, "describe_prepared", pgconn_async_describe_prepared, 1);
	rb_define_method(rb_cPGconn, "describe_portal", pgconn_async_describe_portal, 1);

	rb_define_alias(rb_cPGconn, "async_exec", "exec");
	rb_define_alias(rb_cPGconn, "async_query", "async_exec");
	rb_define_alias(rb_cPGconn, "async_exec_params", "exec_params");
	rb_define_alias(rb_cPGconn, "async_prepare", "prepare");
	rb_define_alias(rb_cPGconn, "async_exec_prepared", "exec_prepared");
	rb_define_alias(rb_cPGconn, "async_describe_prepared", "describe_prepared");
	rb_define_alias(rb_cPGconn, "async_describe_portal", "describe_portal");

	rb_define_method(rb_cPGconn, "make_empty_pgresult", pgconn_make_empty_pgresult, 1);
	rb_define_method(rb_cPGconn, "escape_string", pgconn_s_escape, 1);
	rb_define_alias(rb_cPGconn, "escape", "escape_string");
	rb_define_method(rb_cPGconn, "escape_literal", pgconn_escape_literal, 1);
	rb_define_method(rb_cPGconn, "escape_identifier", pgconn_escape_identifier, 1);
	rb_define_method(rb_cPGconn, "escape_bytea", pgconn_s_escape_bytea, 1);
	rb_define_method(rb_cPGconn, "unescape_bytea", pgconn_s_unescape_bytea, 1);
	rb_define_method(rb_cPGconn, "set_single_row_mode", pgconn_set_single_row_mode, 0);

	/******     PG::Connection INSTANCE METHODS: Asynchronous Command Processing     ******/
	rb_define_method(rb_cPGconn, "send_query", pgconn_send_query, -1);
	rb_define_method(rb_cPGconn, "send_query_params", pgconn_send_query_params, -1);
	rb_define_method(rb_cPGconn, "send_prepare", pgconn_send_prepare, -1);
	rb_define_method(rb_cPGconn, "send_query_prepared", pgconn_send_query_prepared, -1);
	rb_define_method(rb_cPGconn, "send_describe_prepared", pgconn_send_describe_prepared, 1);
	rb_define_method(rb_cPGconn, "send_describe_portal", pgconn_send_describe_portal, 1);
	rb_define_method(rb_cPGconn, "sync_get_result", pgconn_sync_get_result, 0);
	rb_define_method(rb_cPGconn, "consume_input", pgconn_consume_input, 0);
	rb_define_method(rb_cPGconn, "is_busy", pgconn_is_busy, 0);
	rb_define_method(rb_cPGconn, "sync_setnonblocking", pgconn_sync_setnonblocking, 1);
	rb_define_method(rb_cPGconn, "sync_isnonblocking", pgconn_sync_isnonblocking, 0);
	rb_define_method(rb_cPGconn, "sync_flush", pgconn_sync_flush, 0);
	rb_define_method(rb_cPGconn, "flush", pgconn_async_flush, 0);
	rb_define_alias(rb_cPGconn, "async_flush", "flush");
	rb_define_method(rb_cPGconn, "discard_results", pgconn_discard_results, 0);

	/******     PG::Connection INSTANCE METHODS: Cancelling Queries in Progress     ******/
	rb_define_method(rb_cPGconn, "sync_cancel", pgconn_sync_cancel, 0);

	/******     PG::Connection INSTANCE METHODS: NOTIFY     ******/
	rb_define_method(rb_cPGconn, "notifies", pgconn_notifies, 0);

	/******     PG::Connection INSTANCE METHODS: COPY     ******/
	rb_define_method(rb_cPGconn, "sync_put_copy_data", pgconn_sync_put_copy_data, -1);
	rb_define_method(rb_cPGconn, "sync_put_copy_end", pgconn_sync_put_copy_end, -1);
	rb_define_method(rb_cPGconn, "sync_get_copy_data", pgconn_sync_get_copy_data, -1);

	/******     PG::Connection INSTANCE METHODS: Control Functions     ******/
	rb_define_method(rb_cPGconn, "set_error_verbosity", pgconn_set_error_verbosity, 1);
#ifdef HAVE_PQRESULTVERBOSEERRORMESSAGE
	rb_define_method(rb_cPGconn, "set_error_context_visibility", pgconn_set_error_context_visibility, 1 );
#endif
	rb_define_method(rb_cPGconn, "trace", pgconn_trace, 1);
	rb_define_method(rb_cPGconn, "untrace", pgconn_untrace, 0);

	/******     PG::Connection INSTANCE METHODS: Notice Processing     ******/
	rb_define_method(rb_cPGconn, "set_notice_receiver", pgconn_set_notice_receiver, 0);
	rb_define_method(rb_cPGconn, "set_notice_processor", pgconn_set_notice_processor, 0);

	/******     PG::Connection INSTANCE METHODS: Other    ******/
	rb_define_method(rb_cPGconn, "get_client_encoding", pgconn_get_client_encoding, 0);
	rb_define_method(rb_cPGconn, "sync_set_client_encoding", pgconn_sync_set_client_encoding, 1);
	rb_define_method(rb_cPGconn, "set_client_encoding", pgconn_async_set_client_encoding, 1);
	rb_define_alias(rb_cPGconn, "async_set_client_encoding", "set_client_encoding");
	rb_define_alias(rb_cPGconn, "client_encoding=", "set_client_encoding");
	rb_define_method(rb_cPGconn, "block", pgconn_block, -1);
	rb_define_private_method(rb_cPGconn, "flush_data=", pgconn_flush_data_set, 1);
	rb_define_method(rb_cPGconn, "wait_for_notify", pgconn_wait_for_notify, -1);
	rb_define_alias(rb_cPGconn, "notifies_wait", "wait_for_notify");
	rb_define_method(rb_cPGconn, "quote_ident", pgconn_s_quote_ident, 1);
	rb_define_method(rb_cPGconn, "sync_get_last_result", pgconn_sync_get_last_result, 0);
	rb_define_method(rb_cPGconn, "get_last_result", pgconn_async_get_last_result, 0);
	rb_define_alias(rb_cPGconn, "async_get_last_result", "get_last_result");
#ifdef HAVE_PQENCRYPTPASSWORDCONN
	rb_define_method(rb_cPGconn, "sync_encrypt_password", pgconn_sync_encrypt_password, -1);
#endif

#ifdef HAVE_PQSSLATTRIBUTE
	rb_define_method(rb_cPGconn, "ssl_in_use?", pgconn_ssl_in_use, 0);
	rb_define_method(rb_cPGconn, "ssl_attribute", pgconn_ssl_attribute, 1);
	rb_define_method(rb_cPGconn, "ssl_attribute_names", pgconn_ssl_attribute_names, 0);
#endif

#ifdef HAVE_PQENTERPIPELINEMODE
	rb_define_method(rb_cPGconn, "pipeline_status", pgconn_pipeline_status, 0);
	rb_define_method(rb_cPGconn, "enter_pipeline_mode", pgconn_enter_pipeline_mode, 0);
	rb_define_method(rb_cPGconn, "exit_pipeline_mode", pgconn_exit_pipeline_mode, 0);
	rb_define_method(rb_cPGconn, "pipeline_sync", pgconn_pipeline_sync, 0);
	rb_define_method(rb_cPGconn, "send_flush_request", pgconn_send_flush_request, 0);
#endif

	/******     PG::Connection INSTANCE METHODS: Large Object Support     ******/
	rb_define_method(rb_cPGconn, "lo_creat", pgconn_locreat, -1);
	rb_define_alias(rb_cPGconn, "locreat", "lo_creat");
	rb_define_method(rb_cPGconn, "lo_create", pgconn_locreate, 1);
	rb_define_alias(rb_cPGconn, "locreate", "lo_create");
	rb_define_method(rb_cPGconn, "lo_import", pgconn_loimport, 1);
	rb_define_alias(rb_cPGconn, "loimport", "lo_import");
	rb_define_method(rb_cPGconn, "lo_export", pgconn_loexport, 2);
	rb_define_alias(rb_cPGconn, "loexport", "lo_export");
	rb_define_method(rb_cPGconn, "lo_open", pgconn_loopen, -1);
	rb_define_alias(rb_cPGconn, "loopen", "lo_open");
	rb_define_method(rb_cPGconn, "lo_write",pgconn_lowrite, 2);
	rb_define_alias(rb_cPGconn, "lowrite", "lo_write");
	rb_define_method(rb_cPGconn, "lo_read",pgconn_loread, 2);
	rb_define_alias(rb_cPGconn, "loread", "lo_read");
	rb_define_method(rb_cPGconn, "lo_lseek",pgconn_lolseek, 3);
	rb_define_alias(rb_cPGconn, "lolseek", "lo_lseek");
	rb_define_alias(rb_cPGconn, "lo_seek", "lo_lseek");
	rb_define_alias(rb_cPGconn, "loseek", "lo_lseek");
	rb_define_method(rb_cPGconn, "lo_tell",pgconn_lotell, 1);
	rb_define_alias(rb_cPGconn, "lotell", "lo_tell");
	rb_define_method(rb_cPGconn, "lo_truncate", pgconn_lotruncate, 2);
	rb_define_alias(rb_cPGconn, "lotruncate", "lo_truncate");
	rb_define_method(rb_cPGconn, "lo_close",pgconn_loclose, 1);
	rb_define_alias(rb_cPGconn, "loclose", "lo_close");
	rb_define_method(rb_cPGconn, "lo_unlink", pgconn_lounlink, 1);
	rb_define_alias(rb_cPGconn, "lounlink", "lo_unlink");

	rb_define_method(rb_cPGconn, "internal_encoding", pgconn_internal_encoding, 0);
	rb_define_method(rb_cPGconn, "internal_encoding=", pgconn_internal_encoding_set, 1);
	rb_define_method(rb_cPGconn, "external_encoding", pgconn_external_encoding, 0);
	rb_define_method(rb_cPGconn, "set_default_encoding", pgconn_set_default_encoding, 0);

	rb_define_method(rb_cPGconn, "type_map_for_queries=", pgconn_type_map_for_queries_set, 1);
	rb_define_method(rb_cPGconn, "type_map_for_queries", pgconn_type_map_for_queries_get, 0);
	rb_define_method(rb_cPGconn, "type_map_for_results=", pgconn_type_map_for_results_set, 1);
	rb_define_method(rb_cPGconn, "type_map_for_results", pgconn_type_map_for_results_get, 0);
	rb_define_method(rb_cPGconn, "encoder_for_put_copy_data=", pgconn_encoder_for_put_copy_data_set, 1);
	rb_define_method(rb_cPGconn, "encoder_for_put_copy_data", pgconn_encoder_for_put_copy_data_get, 0);
	rb_define_method(rb_cPGconn, "decoder_for_get_copy_data=", pgconn_decoder_for_get_copy_data_set, 1);
	rb_define_method(rb_cPGconn, "decoder_for_get_copy_data", pgconn_decoder_for_get_copy_data_get, 0);

	rb_define_method(rb_cPGconn, "field_name_type=", pgconn_field_name_type_set, 1 );
	rb_define_method(rb_cPGconn, "field_name_type", pgconn_field_name_type_get, 0 );
}
