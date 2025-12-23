# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    # OpenTelemetry semantic conventions from v1.10.
    #
    # @deprecated This module is deprecated in favor of the namespaced modules under
    #   {OpenTelemetry::SemConv::Incubating} (all experimental and stable) and
    #   {OpenTelemetry::SemConv} (stable)
    module Trace
      # The full invoked ARN as provided on the `Context` passed to the function (`Lambda-Runtime-Invoked-Function-Arn` header on the `/runtime/invocation/next` applicable)
      # @note This may be different from `faas.id` if an alias is involved
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_LAMBDA_INVOKED_ARN} for its replacement.
      AWS_LAMBDA_INVOKED_ARN = 'aws.lambda.invoked_arn'

      # The [event_id](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#id) uniquely identifies the event
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUDEVENTS::CLOUDEVENTS_EVENT_ID} for its replacement.
      CLOUDEVENTS_EVENT_ID = 'cloudevents.event_id'

      # The [source](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#source-1) identifies the context in which an event happened
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUDEVENTS::CLOUDEVENTS_EVENT_SOURCE} for its replacement.
      CLOUDEVENTS_EVENT_SOURCE = 'cloudevents.event_source'

      # The [version of the CloudEvents specification](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#specversion) which the event uses
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUDEVENTS::CLOUDEVENTS_EVENT_SPEC_VERSION} for its replacement.
      CLOUDEVENTS_EVENT_SPEC_VERSION = 'cloudevents.event_spec_version'

      # The [event_type](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) contains a value describing the type of event related to the originating occurrence
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUDEVENTS::CLOUDEVENTS_EVENT_TYPE} for its replacement.
      CLOUDEVENTS_EVENT_TYPE = 'cloudevents.event_type'

      # The [subject](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#subject) of the event in the context of the event producer (identified by source)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUDEVENTS::CLOUDEVENTS_EVENT_SUBJECT} for its replacement.
      CLOUDEVENTS_EVENT_SUBJECT = 'cloudevents.event_subject'

      # Parent-child Reference type
      # @note The causal relationship between a child Span and a parent Span
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::OPENTRACING::OPENTRACING_REF_TYPE} for its replacement.
      OPENTRACING_REF_TYPE = 'opentracing.ref_type'

      # An identifier for the database management system (DBMS) product being used. See below for a list of well-known identifiers
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_SYSTEM} for its replacement.
      DB_SYSTEM = 'db.system'

      # The connection string used to connect to the database. It is recommended to remove embedded credentials
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CONNECTION_STRING} for its replacement.
      DB_CONNECTION_STRING = 'db.connection_string'

      # Username for accessing the database
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_USER} for its replacement.
      DB_USER = 'db.user'

      # The fully-qualified class name of the [Java Database Connectivity (JDBC)](https://docs.oracle.com/javase/8/docs/technotes/guides/jdbc/) driver used to connect
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_JDBC_DRIVER_CLASSNAME} for its replacement.
      DB_JDBC_DRIVER_CLASSNAME = 'db.jdbc.driver_classname'

      # This attribute is used to report the name of the database being accessed. For commands that switch the database, this should be set to the target database (even if the command fails)
      # @note In some SQL databases, the database name to be used is called "schema name". In case there are multiple layers that could be considered for database name (e.g. Oracle instance name and schema name), the database name to be used is the more specific layer (e.g. Oracle schema name)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_NAME} for its replacement.
      DB_NAME = 'db.name'

      # The database statement being executed
      # @note The value may be sanitized to exclude sensitive information
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_STATEMENT} for its replacement.
      DB_STATEMENT = 'db.statement'

      # The name of the operation being executed, e.g. the [MongoDB command name](https://docs.mongodb.com/manual/reference/command/#database-operations) such as `findAndModify`, or the SQL keyword
      # @note When setting this to an SQL keyword, it is not recommended to attempt any client-side parsing of `db.statement` just to get this property, but it should be set if the operation name is provided by the library being instrumented. If the SQL statement has an ambiguous operation, or performs more than one operation, this value may be omitted
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_OPERATION} for its replacement.
      DB_OPERATION = 'db.operation'

      # Remote hostname or similar, see note below
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_PEER_NAME} for its replacement.
      NET_PEER_NAME = 'net.peer.name'

      # Remote address of the peer (dotted decimal for IPv4 or [RFC5952](https://tools.ietf.org/html/rfc5952) for IPv6)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_SOCK_PEER_ADDR} for its replacement.
      NET_PEER_IP = 'net.peer.ip'

      # Remote port number
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_PEER_PORT} for its replacement.
      NET_PEER_PORT = 'net.peer.port'

      # Transport protocol used. See note below
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_TRANSPORT} for its replacement.
      NET_TRANSPORT = 'net.transport'

      # The Microsoft SQL Server [instance name](https://docs.microsoft.com/en-us/sql/connect/jdbc/building-the-connection-url?view=sql-server-ver15) connecting to. This name is used to determine the port of a named instance
      # @note If setting a `db.mssql.instance_name`, `net.peer.port` is no longer required (but still recommended if non-standard)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_MSSQL_INSTANCE_NAME} for its replacement.
      DB_MSSQL_INSTANCE_NAME = 'db.mssql.instance_name'

      # The fetch size used for paging, i.e. how many rows will be returned at once
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_PAGE_SIZE} for its replacement.
      DB_CASSANDRA_PAGE_SIZE = 'db.cassandra.page_size'

      # The consistency level of the query. Based on consistency values from [CQL](https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/dml/dmlConfigConsistency.html)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_CONSISTENCY_LEVEL} for its replacement.
      DB_CASSANDRA_CONSISTENCY_LEVEL = 'db.cassandra.consistency_level'

      # The name of the primary table that the operation is acting upon, including the keyspace name (if applicable)
      # @note This mirrors the db.sql.table attribute but references cassandra rather than sql. It is not recommended to attempt any client-side parsing of `db.statement` just to get this property, but it should be set if it is provided by the library being instrumented. If the operation is acting upon an anonymous table, or more than one table, this value MUST NOT be set
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_TABLE} for its replacement.
      DB_CASSANDRA_TABLE = 'db.cassandra.table'

      # Whether or not the query is idempotent
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_IDEMPOTENCE} for its replacement.
      DB_CASSANDRA_IDEMPOTENCE = 'db.cassandra.idempotence'

      # The number of times a query was speculatively executed. Not set or `0` if the query was not executed speculatively
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_SPECULATIVE_EXECUTION_COUNT} for its replacement.
      DB_CASSANDRA_SPECULATIVE_EXECUTION_COUNT = 'db.cassandra.speculative_execution_count'

      # The ID of the coordinating node for a query
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_COORDINATOR_ID} for its replacement.
      DB_CASSANDRA_COORDINATOR_ID = 'db.cassandra.coordinator.id'

      # The data center of the coordinating node for a query
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_CASSANDRA_COORDINATOR_DC} for its replacement.
      DB_CASSANDRA_COORDINATOR_DC = 'db.cassandra.coordinator.dc'

      # The index of the database being accessed as used in the [`SELECT` command](https://redis.io/commands/select), provided as an integer. To be used instead of the generic `db.name` attribute
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_REDIS_DATABASE_INDEX} for its replacement.
      DB_REDIS_DATABASE_INDEX = 'db.redis.database_index'

      # The collection being accessed within the database stated in `db.name`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_MONGODB_COLLECTION} for its replacement.
      DB_MONGODB_COLLECTION = 'db.mongodb.collection'

      # The name of the primary table that the operation is acting upon, including the database name (if applicable)
      # @note It is not recommended to attempt any client-side parsing of `db.statement` just to get this property, but it should be set if it is provided by the library being instrumented. If the operation is acting upon an anonymous table, or more than one table, this value MUST NOT be set
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DB::DB_SQL_TABLE} for its replacement.
      DB_SQL_TABLE = 'db.sql.table'

      # The type of the exception (its fully-qualified class name, if applicable). The dynamic type of the exception should be preferred over the static type in languages that support it
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::EXCEPTION::EXCEPTION_TYPE} for its replacement.
      EXCEPTION_TYPE = 'exception.type'

      # The exception message
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::EXCEPTION::EXCEPTION_MESSAGE} for its replacement.
      EXCEPTION_MESSAGE = 'exception.message'

      # A stacktrace as a string in the natural representation for the language runtime. The representation is to be determined and documented by each language SIG
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::EXCEPTION::EXCEPTION_STACKTRACE} for its replacement.
      EXCEPTION_STACKTRACE = 'exception.stacktrace'

      # SHOULD be set to true if the exception event is recorded at a point where it is known that the exception is escaping the scope of the span
      # @note An exception is considered to have escaped (or left) the scope of a span,
      #  if that span is ended while the exception is still logically "in flight".
      #  This may be actually "in flight" in some languages (e.g. if the exception
      #  is passed to a Context manager's `__exit__` method in Python) but will
      #  usually be caught at the point of recording the exception in most languages.
      #
      #  It is usually not possible to determine at the point where an exception is thrown
      #  whether it will escape the scope of a span.
      #  However, it is trivial to know that an exception
      #  will escape, if one checks for an active exception just before ending the span,
      #  as done in the [example above](#recording-an-exception).
      #
      #  It follows that an exception may still escape the scope of the span
      #  even if the `exception.escaped` attribute was not set or set to false,
      #  since the event might have been recorded at a time where it was not
      #  clear whether the exception will escape
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::EXCEPTION::EXCEPTION_ESCAPED} for its replacement.
      EXCEPTION_ESCAPED = 'exception.escaped'

      # Type of the trigger which caused this function execution
      # @note For the server/consumer span on the incoming side,
      #  `faas.trigger` MUST be set.
      #
      #  Clients invoking FaaS instances usually cannot set `faas.trigger`,
      #  since they would typically need to look in the payload to determine
      #  the event type. If clients set it, it should be the same as the
      #  trigger that corresponding incoming would have (i.e., this has
      #  nothing to do with the underlying transport used to make the API
      #  call to invoke the lambda, which is often HTTP)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_TRIGGER} for its replacement.
      FAAS_TRIGGER = 'faas.trigger'

      # The execution ID of the current function execution
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_INVOCATION_ID} for its replacement.
      FAAS_EXECUTION = 'faas.execution'

      # The name of the source on which the triggering operation was performed. For example, in Cloud Storage or S3 corresponds to the bucket name, and in Cosmos DB to the database name
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_DOCUMENT_COLLECTION} for its replacement.
      FAAS_DOCUMENT_COLLECTION = 'faas.document.collection'

      # Describes the type of the operation that was performed on the data
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_DOCUMENT_OPERATION} for its replacement.
      FAAS_DOCUMENT_OPERATION = 'faas.document.operation'

      # A string containing the time when the data was accessed in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format expressed in [UTC](https://www.w3.org/TR/NOTE-datetime)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_DOCUMENT_TIME} for its replacement.
      FAAS_DOCUMENT_TIME = 'faas.document.time'

      # The document name/table subjected to the operation. For example, in Cloud Storage or S3 is the name of the file, and in Cosmos DB the table name
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_DOCUMENT_NAME} for its replacement.
      FAAS_DOCUMENT_NAME = 'faas.document.name'

      # HTTP request method
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_METHOD} for its replacement.
      HTTP_METHOD = 'http.method'

      # Full HTTP request URL in the form `scheme://host[:port]/path?query[#fragment]`. Usually the fragment is not transmitted over HTTP, but if it is known, it should be included nevertheless
      # @note `http.url` MUST NOT contain credentials passed via URL in form of `https://username:password@www.example.com/`. In such case the attribute's value should be `https://www.example.com/`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_URL} for its replacement.
      HTTP_URL = 'http.url'

      # The full request target as passed in a HTTP request line or equivalent
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_TARGET} for its replacement.
      HTTP_TARGET = 'http.target'

      # The value of the [HTTP host header](https://tools.ietf.org/html/rfc7230#section-5.4). An empty Host header should also be reported, see note
      # @note When the header is present but empty the attribute SHOULD be set to the empty string. Note that this is a valid situation that is expected in certain cases, according the aforementioned [section of RFC 7230](https://tools.ietf.org/html/rfc7230#section-5.4). When the header is not set the attribute MUST NOT be set
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_REQUEST_HEADER_LAMBDA} for its replacement.
      HTTP_HOST = 'http.host'

      # The URI scheme identifying the used protocol
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_SCHEME} for its replacement.
      HTTP_SCHEME = 'http.scheme'

      # [HTTP response status code](https://tools.ietf.org/html/rfc7231#section-6)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_STATUS_CODE} for its replacement.
      HTTP_STATUS_CODE = 'http.status_code'

      # Kind of HTTP protocol used
      # @note If `net.transport` is not specified, it can be assumed to be `IP.TCP` except if `http.flavor` is `QUIC`, in which case `IP.UDP` is assumed
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_FLAVOR} for its replacement.
      HTTP_FLAVOR = 'http.flavor'

      # Value of the [HTTP User-Agent](https://tools.ietf.org/html/rfc7231#section-5.5.3) header sent by the client
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_USER_AGENT} for its replacement.
      HTTP_USER_AGENT = 'http.user_agent'

      # The size of the request payload body in bytes. This is the number of bytes transferred excluding headers and is often, but not always, present as the [Content-Length](https://tools.ietf.org/html/rfc7230#section-3.3.2) header. For requests using transport encoding, this should be the compressed size
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_REQUEST_CONTENT_LENGTH} for its replacement.
      HTTP_REQUEST_CONTENT_LENGTH = 'http.request_content_length'

      # The size of the uncompressed request payload body after transport decoding. Not set if transport encoding not used
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   There is no replacement.
      #   Consider using the bare content length with {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_REQUEST_CONTENT_LENGTH} instead.
      HTTP_REQUEST_CONTENT_LENGTH_UNCOMPRESSED = 'http.request_content_length_uncompressed'

      # The size of the response payload body in bytes. This is the number of bytes transferred excluding headers and is often, but not always, present as the [Content-Length](https://tools.ietf.org/html/rfc7230#section-3.3.2) header. For requests using transport encoding, this should be the compressed size
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_RESPONSE_CONTENT_LENGTH} for its replacement.
      HTTP_RESPONSE_CONTENT_LENGTH = 'http.response_content_length'

      # The size of the uncompressed response payload body after transport decoding. Not set if transport encoding not used
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   There is no replacement.
      #   Consider using the bare content length with {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_RESPONSE_CONTENT_LENGTH} instead.
      HTTP_RESPONSE_CONTENT_LENGTH_UNCOMPRESSED = 'http.response_content_length_uncompressed'

      # The ordinal number of request re-sending attempt
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_REQUEST_RESEND_COUNT} for its replacement.
      HTTP_RETRY_COUNT = 'http.retry_count'

      # The primary server name of the matched virtual host. This should be obtained via configuration. If no such configuration can be obtained, this attribute MUST NOT be set ( `net.host.name` should be used instead)
      # @note `http.url` is usually not readily available on the server side but would have to be assembled in a cumbersome and sometimes lossy process from other information (see e.g. open-telemetry/opentelemetry-python/pull/148). It is thus preferred to supply the raw data that is available
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_HOST_NAME} for its replacement.
      HTTP_SERVER_NAME = 'http.server_name'

      # The matched route (path template)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HTTP::HTTP_ROUTE} for its replacement.
      HTTP_ROUTE = 'http.route'

      # The IP address of the original client behind all proxies, if known (e.g. from [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For))
      # @note This is not necessarily the same as `net.peer.ip`, which would
      #  identify the network-level peer, which may be a proxy.
      #
      #  This attribute should be set when a source of information different
      #  from the one used for `net.peer.ip`, is available even if that other
      #  source just confirms the same value as `net.peer.ip`.
      #  Rationale: For `net.peer.ip`, one typically does not know if it
      #  comes from a proxy, reverse proxy, or the actual client. Setting
      #  `http.client_ip` when it's the same as `net.peer.ip` means that
      #  one is at least somewhat confident that the address is not that of
      #  the closest proxy
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLIENT::CLIENT_ADDRESS} for its replacement.
      HTTP_CLIENT_IP = 'http.client_ip'

      # Like `net.peer.ip` but for the host IP. Useful in case of a multi-IP host
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_SOCK_HOST_ADDR} for its replacement.
      NET_HOST_IP = 'net.host.ip'

      # Like `net.peer.port` but for the host port
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_HOST_PORT} for its replacement.
      NET_HOST_PORT = 'net.host.port'

      # Local hostname or similar, see note below
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_HOST_NAME} for its replacement.
      NET_HOST_NAME = 'net.host.name'

      # The internet connection type currently being used by the host
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CONNECTION_TYPE} for its replacement.
      NET_HOST_CONNECTION_TYPE = 'net.host.connection.type'

      # This describes more details regarding the connection.type. It may be the type of cell technology connection, but it could be used for describing details about a wifi connection
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CONNECTION_SUBTYPE} for its replacement.
      NET_HOST_CONNECTION_SUBTYPE = 'net.host.connection.subtype'

      # The name of the mobile carrier
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CARRIER_NAME} for its replacement.
      NET_HOST_CARRIER_NAME = 'net.host.carrier.name'

      # The mobile carrier country code
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CARRIER_MCC} for its replacement.
      NET_HOST_CARRIER_MCC = 'net.host.carrier.mcc'

      # The mobile carrier network code
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CARRIER_MNC} for its replacement.
      NET_HOST_CARRIER_MNC = 'net.host.carrier.mnc'

      # The ISO 3166-1 alpha-2 2-character country code associated with the mobile carrier network
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NETWORK::NETWORK_CARRIER_ICC} for its replacement.
      NET_HOST_CARRIER_ICC = 'net.host.carrier.icc'

      # A string identifying the messaging system
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM} for its replacement.
      MESSAGING_SYSTEM = 'messaging.system'

      # The message destination name. This might be equal to the span name but is required nevertheless
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME} for its replacement.
      MESSAGING_DESTINATION = 'messaging.destination'

      # The kind of message destination
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   This attribute was renamed in v1.17.0 and its replacement was removed in v1.20.0.
      MESSAGING_DESTINATION_KIND = 'messaging.destination_kind'

      # A boolean that is true if the message destination is temporary
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_TEMPORARY} for its replacement.
      MESSAGING_TEMP_DESTINATION = 'messaging.temp_destination'

      # The name of the transport protocol
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_PROTOCOL_NAME} for its replacement.
      MESSAGING_PROTOCOL = 'messaging.protocol'

      # The version of the transport protocol
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::NET::NET_PROTOCOL_VERSION} for its replacement.
      MESSAGING_PROTOCOL_VERSION = 'messaging.protocol_version'

      # Connection string
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   This attribute was removed in v1.17.0.
      MESSAGING_URL = 'messaging.url'

      # A value used by the messaging system as an identifier for the message, represented as a string
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_MESSAGE_ID} for its replacement.
      MESSAGING_MESSAGE_ID = 'messaging.message_id'

      # The [conversation ID](#conversations) identifying the conversation to which the message belongs, represented as a string. Sometimes called "Correlation ID"
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_MESSAGE_CONVERSATION_ID} for its replacement.
      MESSAGING_CONVERSATION_ID = 'messaging.conversation_id'

      # The (uncompressed) size of the message payload in bytes. Also use this attribute if it is unknown whether the compressed or uncompressed payload size is reported
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_MESSAGE_BODY_SIZE} for its replacement.
      MESSAGING_MESSAGE_PAYLOAD_SIZE_BYTES = 'messaging.message_payload_size_bytes'

      # The compressed size of the message payload in bytes
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   This attribute was removed in v1.22.0.
      MESSAGING_MESSAGE_PAYLOAD_COMPRESSED_SIZE_BYTES = 'messaging.message_payload_compressed_size_bytes'

      # A string containing the function invocation time in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format expressed in [UTC](https://www.w3.org/TR/NOTE-datetime)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_TIME} for its replacement.
      FAAS_TIME = 'faas.time'

      # A string containing the schedule period as [Cron Expression](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_CRON} for its replacement.
      FAAS_CRON = 'faas.cron'

      # A boolean that is true if the serverless function is executed for the first time (aka cold-start)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_COLDSTART} for its replacement.
      FAAS_COLDSTART = 'faas.coldstart'

      # The name of the invoked function
      # @note SHOULD be equal to the `faas.name` resource attribute of the invoked function
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_INVOKED_NAME} for its replacement.
      FAAS_INVOKED_NAME = 'faas.invoked_name'

      # The cloud provider of the invoked function
      # @note SHOULD be equal to the `cloud.provider` resource attribute of the invoked function
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_INVOKED_PROVIDER} for its replacement.
      FAAS_INVOKED_PROVIDER = 'faas.invoked_provider'

      # The cloud region of the invoked function
      # @note SHOULD be equal to the `cloud.region` resource attribute of the invoked function
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_INVOKED_REGION} for its replacement.
      FAAS_INVOKED_REGION = 'faas.invoked_region'

      # The [`service.name`](../../resource/semantic_conventions/README.md#service) of the remote service. SHOULD be equal to the actual `service.name` resource attribute of the remote service if any
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PEER::PEER_SERVICE} for its replacement.
      PEER_SERVICE = 'peer.service'

      # Username or client_id extracted from the access token or [Authorization](https://tools.ietf.org/html/rfc7235#section-4.2) header in the inbound request from outside the system
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::ENDUSER::ENDUSER_ID} for its replacement.
      ENDUSER_ID = 'enduser.id'

      # Actual/assumed role the client is making the request under extracted from token or application security context
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::ENDUSER::ENDUSER_ROLE} for its replacement.
      ENDUSER_ROLE = 'enduser.role'

      # Scopes or granted authorities the client currently possesses extracted from token or application security context. The value would come from the scope associated with an [OAuth 2.0 Access Token](https://tools.ietf.org/html/rfc6749#section-3.3) or an attribute value in a [SAML 2.0 Assertion](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::ENDUSER::ENDUSER_SCOPE} for its replacement.
      ENDUSER_SCOPE = 'enduser.scope'

      # Current "managed" thread ID (as opposed to OS thread ID)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::THREAD::THREAD_ID} for its replacement.
      THREAD_ID = 'thread.id'

      # Current thread name
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::THREAD::THREAD_NAME} for its replacement.
      THREAD_NAME = 'thread.name'

      # The method or function name, or equivalent (usually rightmost part of the code unit's name)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CODE::CODE_FUNCTION} for its replacement.
      CODE_FUNCTION = 'code.function'

      # The "namespace" within which `code.function` is defined. Usually the qualified class or module name, such that `code.namespace` + some separator + `code.function` form a unique identifier for the code unit
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CODE::CODE_NAMESPACE} for its replacement.
      CODE_NAMESPACE = 'code.namespace'

      # The source code file name that identifies the code unit as uniquely as possible (preferably an absolute file path)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CODE::CODE_FILEPATH} for its replacement.
      CODE_FILEPATH = 'code.filepath'

      # The line number in `code.filepath` best representing the operation. It SHOULD point within the code unit named in `code.function`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CODE::CODE_LINENO} for its replacement.
      CODE_LINENO = 'code.lineno'

      # The value `aws-api`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_SYSTEM} for its replacement.
      RPC_SYSTEM = 'rpc.system'

      # The name of the service to which a request is made, as returned by the AWS SDK
      # @note This is the logical name of the service from the RPC interface perspective, which can be different from the name of any implementing class. The `code.namespace` attribute may be used to store the latter (despite the attribute name, it may include a class name; e.g., class with method actually executing the call on the server side, RPC client stub class on the client side)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_SERVICE} for its replacement.
      RPC_SERVICE = 'rpc.service'

      # The name of the operation corresponding to the request, as returned by the AWS SDK
      # @note This is the logical name of the method from the RPC interface perspective, which can be different from the name of any implementing method/function. The `code.function` attribute may be used to store the latter (e.g., method actually executing the call on the server side, RPC client stub method on the client side)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_METHOD} for its replacement.
      RPC_METHOD = 'rpc.method'

      # The keys in the `RequestItems` object field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_TABLE_NAMES} for its replacement.
      AWS_DYNAMODB_TABLE_NAMES = 'aws.dynamodb.table_names'

      # The JSON-serialized value of each item in the `ConsumedCapacity` response field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_CONSUMED_CAPACITY} for its replacement.
      AWS_DYNAMODB_CONSUMED_CAPACITY = 'aws.dynamodb.consumed_capacity'

      # The JSON-serialized value of the `ItemCollectionMetrics` response field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_ITEM_COLLECTION_METRICS} for its replacement.
      AWS_DYNAMODB_ITEM_COLLECTION_METRICS = 'aws.dynamodb.item_collection_metrics'

      # The value of the `ProvisionedThroughput.ReadCapacityUnits` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_PROVISIONED_READ_CAPACITY} for its replacement.
      AWS_DYNAMODB_PROVISIONED_READ_CAPACITY = 'aws.dynamodb.provisioned_read_capacity'

      # The value of the `ProvisionedThroughput.WriteCapacityUnits` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_PROVISIONED_WRITE_CAPACITY} for its replacement.
      AWS_DYNAMODB_PROVISIONED_WRITE_CAPACITY = 'aws.dynamodb.provisioned_write_capacity'

      # The value of the `ConsistentRead` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_CONSISTENT_READ} for its replacement.
      AWS_DYNAMODB_CONSISTENT_READ = 'aws.dynamodb.consistent_read'

      # The value of the `ProjectionExpression` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_PROJECTION} for its replacement.
      AWS_DYNAMODB_PROJECTION = 'aws.dynamodb.projection'

      # The value of the `Limit` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_LIMIT} for its replacement.
      AWS_DYNAMODB_LIMIT = 'aws.dynamodb.limit'

      # The value of the `AttributesToGet` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_ATTRIBUTES_TO_GET} for its replacement.
      AWS_DYNAMODB_ATTRIBUTES_TO_GET = 'aws.dynamodb.attributes_to_get'

      # The value of the `IndexName` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_INDEX_NAME} for its replacement.
      AWS_DYNAMODB_INDEX_NAME = 'aws.dynamodb.index_name'

      # The value of the `Select` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_SELECT} for its replacement.
      AWS_DYNAMODB_SELECT = 'aws.dynamodb.select'

      # The JSON-serialized value of each item of the `GlobalSecondaryIndexes` request field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_GLOBAL_SECONDARY_INDEXES} for its replacement.
      AWS_DYNAMODB_GLOBAL_SECONDARY_INDEXES = 'aws.dynamodb.global_secondary_indexes'

      # The JSON-serialized value of each item of the `LocalSecondaryIndexes` request field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_LOCAL_SECONDARY_INDEXES} for its replacement.
      AWS_DYNAMODB_LOCAL_SECONDARY_INDEXES = 'aws.dynamodb.local_secondary_indexes'

      # The value of the `ExclusiveStartTableName` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_EXCLUSIVE_START_TABLE} for its replacement.
      AWS_DYNAMODB_EXCLUSIVE_START_TABLE = 'aws.dynamodb.exclusive_start_table'

      # The the number of items in the `TableNames` response parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_TABLE_COUNT} for its replacement.
      AWS_DYNAMODB_TABLE_COUNT = 'aws.dynamodb.table_count'

      # The value of the `ScanIndexForward` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_SCAN_FORWARD} for its replacement.
      AWS_DYNAMODB_SCAN_FORWARD = 'aws.dynamodb.scan_forward'

      # The value of the `Segment` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_SEGMENT} for its replacement.
      AWS_DYNAMODB_SEGMENT = 'aws.dynamodb.segment'

      # The value of the `TotalSegments` request parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_TOTAL_SEGMENTS} for its replacement.
      AWS_DYNAMODB_TOTAL_SEGMENTS = 'aws.dynamodb.total_segments'

      # The value of the `Count` response parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_COUNT} for its replacement.
      AWS_DYNAMODB_COUNT = 'aws.dynamodb.count'

      # The value of the `ScannedCount` response parameter
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_SCANNED_COUNT} for its replacement.
      AWS_DYNAMODB_SCANNED_COUNT = 'aws.dynamodb.scanned_count'

      # The JSON-serialized value of each item in the `AttributeDefinitions` request field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_ATTRIBUTE_DEFINITIONS} for its replacement.
      AWS_DYNAMODB_ATTRIBUTE_DEFINITIONS = 'aws.dynamodb.attribute_definitions'

      # The JSON-serialized value of each item in the the `GlobalSecondaryIndexUpdates` request field
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_DYNAMODB_GLOBAL_SECONDARY_INDEX_UPDATES} for its replacement.
      AWS_DYNAMODB_GLOBAL_SECONDARY_INDEX_UPDATES = 'aws.dynamodb.global_secondary_index_updates'

      # A string identifying the kind of message consumption as defined in the [Operation names](#operation-names) section above. If the operation is "send", this attribute MUST NOT be set, since the operation can be inferred from the span kind in that case
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_OPERATION} for its replacement.
      MESSAGING_OPERATION = 'messaging.operation'

      # The identifier for the consumer receiving a message. For Kafka, set it to `{messaging.kafka.consumer_group} - {messaging.kafka.client_id}`, if both are present, or only `messaging.kafka.consumer_group`. For brokers, such as RabbitMQ and Artemis, set it to the `client_id` of the client consuming the message
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_CLIENT_ID} for its replacement.
      MESSAGING_CONSUMER_ID = 'messaging.consumer_id'

      # RabbitMQ message routing key
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_RABBITMQ_DESTINATION_ROUTING_KEY} for its replacement.
      MESSAGING_RABBITMQ_ROUTING_KEY = 'messaging.rabbitmq.routing_key'

      # Message keys in Kafka are used for grouping alike messages to ensure they're processed on the same partition. They differ from `messaging.message_id` in that they're not unique. If the key is `null`, the attribute MUST NOT be set
      # @note If the key type is not string, it's string representation has to be supplied for the attribute. If the key has no unambiguous, canonical string form, don't include its value
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_KAFKA_MESSAGE_KEY} for its replacement.
      MESSAGING_KAFKA_MESSAGE_KEY = 'messaging.kafka.message_key'

      # Name of the Kafka Consumer Group that is handling the message. Only applies to consumers, not producers
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_KAFKA_CONSUMER_GROUP} for its replacement.
      MESSAGING_KAFKA_CONSUMER_GROUP = 'messaging.kafka.consumer_group'

      # Client Id for the Consumer or Producer that is handling the message
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_CLIENT_ID} for its replacement.
      MESSAGING_KAFKA_CLIENT_ID = 'messaging.kafka.client_id'

      # Partition the message is sent to
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_KAFKA_DESTINATION_PARTITION} for its replacement.
      MESSAGING_KAFKA_PARTITION = 'messaging.kafka.partition'

      # A boolean that is true if the message is a tombstone
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_KAFKA_MESSAGE_TOMBSTONE} for its replacement.
      MESSAGING_KAFKA_TOMBSTONE = 'messaging.kafka.tombstone'

      # Namespace of RocketMQ resources, resources in different namespaces are individual
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_NAMESPACE} for its replacement.
      MESSAGING_ROCKETMQ_NAMESPACE = 'messaging.rocketmq.namespace'

      # Name of the RocketMQ producer/consumer group that is handling the message. The client type is identified by the SpanKind
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_CLIENT_GROUP} for its replacement.
      MESSAGING_ROCKETMQ_CLIENT_GROUP = 'messaging.rocketmq.client_group'

      # The unique identifier for each client
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_CLIENT_ID} for its replacement.
      MESSAGING_ROCKETMQ_CLIENT_ID = 'messaging.rocketmq.client_id'

      # Type of message
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_MESSAGE_TYPE} for its replacement.
      MESSAGING_ROCKETMQ_MESSAGE_TYPE = 'messaging.rocketmq.message_type'

      # The secondary classifier of message besides topic
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_MESSAGE_TAG} for its replacement.
      MESSAGING_ROCKETMQ_MESSAGE_TAG = 'messaging.rocketmq.message_tag'

      # Key(s) of message, another way to mark message besides message id
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_MESSAGE_KEYS} for its replacement.
      MESSAGING_ROCKETMQ_MESSAGE_KEYS = 'messaging.rocketmq.message_keys'

      # Model of message consumption. This only applies to consumer spans
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGING::MESSAGING_ROCKETMQ_CONSUMPTION_MODEL} for its replacement.
      MESSAGING_ROCKETMQ_CONSUMPTION_MODEL = 'messaging.rocketmq.consumption_model'

      # The [numeric status code](https://github.com/grpc/grpc/blob/v1.33.2/doc/statuscodes.md) of the gRPC request
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_GRPC_STATUS_CODE} for its replacement.
      RPC_GRPC_STATUS_CODE = 'rpc.grpc.status_code'

      # Protocol version as in `jsonrpc` property of request/response. Since JSON-RPC 1.0 does not specify this, the value can be omitted
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_JSONRPC_VERSION} for its replacement.
      RPC_JSONRPC_VERSION = 'rpc.jsonrpc.version'

      # `id` property of request or response. Since protocol allows id to be int, string, `null` or missing (for notifications), value is expected to be cast to string for simplicity. Use empty string in case of `null` value. Omit entirely if this is a notification
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_JSONRPC_REQUEST_ID} for its replacement.
      RPC_JSONRPC_REQUEST_ID = 'rpc.jsonrpc.request_id'

      # `error.code` property of response if it is an error response
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_JSONRPC_ERROR_CODE} for its replacement.
      RPC_JSONRPC_ERROR_CODE = 'rpc.jsonrpc.error_code'

      # `error.message` property of response if it is an error response
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::RPC::RPC_JSONRPC_ERROR_MESSAGE} for its replacement.
      RPC_JSONRPC_ERROR_MESSAGE = 'rpc.jsonrpc.error_message'

      # Whether this is a received or sent message
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGE::MESSAGE_TYPE} for its replacement.
      MESSAGE_TYPE = 'message.type'

      # MUST be calculated as two different counters starting from `1` one for sent messages and one for received message
      # @note This way we guarantee that the values will be consistent between different implementations
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGE::MESSAGE_ID} for its replacement.
      MESSAGE_ID = 'message.id'

      # Compressed size of the message in bytes
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGE::MESSAGE_COMPRESSED_SIZE} for its replacement.
      MESSAGE_COMPRESSED_SIZE = 'message.compressed_size'

      # Uncompressed size of the message in bytes
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Trace\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::MESSAGE::MESSAGE_UNCOMPRESSED_SIZE} for its replacement.
      MESSAGE_UNCOMPRESSED_SIZE = 'message.uncompressed_size'

    end
  end
end
