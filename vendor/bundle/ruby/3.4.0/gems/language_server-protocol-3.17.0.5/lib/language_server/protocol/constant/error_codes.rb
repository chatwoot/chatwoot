module LanguageServer
  module Protocol
    module Constant
      module ErrorCodes
        PARSE_ERROR = -32700
        INVALID_REQUEST = -32600
        METHOD_NOT_FOUND = -32601
        INVALID_PARAMS = -32602
        INTERNAL_ERROR = -32603
        #
        # This is the start range of JSON-RPC reserved error codes.
        # It doesn't denote a real error code. No LSP error codes should
        # be defined between the start and end range. For backwards
        # compatibility the `ServerNotInitialized` and the `UnknownErrorCode`
        # are left in the range.
        #
        JSONRPC_RESERVED_ERROR_RANGE_START = -32099
        SERVER_ERROR_START = JSONRPC_RESERVED_ERROR_RANGE_START
        #
        # Error code indicating that a server received a notification or
        # request before the server has received the `initialize` request.
        #
        SERVER_NOT_INITIALIZED = -32002
        UNKNOWN_ERROR_CODE = -32001
        #
        # This is the end range of JSON-RPC reserved error codes.
        # It doesn't denote a real error code.
        #
        JSONRPC_RESERVED_ERROR_RANGE_END = -32000
        SERVER_ERROR_END = JSONRPC_RESERVED_ERROR_RANGE_END
        #
        # This is the start range of LSP reserved error codes.
        # It doesn't denote a real error code.
        #
        LSP_RESERVED_ERROR_RANGE_START = -32899
        #
        # A request failed but it was syntactically correct, e.g the
        # method name was known and the parameters were valid. The error
        # message should contain human readable information about why
        # the request failed.
        #
        REQUEST_FAILED = -32803
        #
        # The server cancelled the request. This error code should
        # only be used for requests that explicitly support being
        # server cancellable.
        #
        SERVER_CANCELLED = -32802
        #
        # The server detected that the content of a document got
        # modified outside normal conditions. A server should
        # NOT send this error code if it detects a content change
        # in it unprocessed messages. The result even computed
        # on an older state might still be useful for the client.
        #
        # If a client decides that a result is not of any use anymore
        # the client should cancel the request.
        #
        CONTENT_MODIFIED = -32801
        #
        # The client has canceled a request and a server as detected
        # the cancel.
        #
        REQUEST_CANCELLED = -32800
        #
        # This is the end range of LSP reserved error codes.
        # It doesn't denote a real error code.
        #
        LSP_RESERVED_ERROR_RANGE_END = -32800
      end
    end
  end
end
