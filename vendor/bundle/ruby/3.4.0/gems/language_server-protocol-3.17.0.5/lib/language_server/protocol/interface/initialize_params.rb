module LanguageServer
  module Protocol
    module Interface
      class InitializeParams
        def initialize(work_done_token: nil, process_id:, client_info: nil, locale: nil, root_path: nil, root_uri:, initialization_options: nil, capabilities:, trace: nil, workspace_folders: nil)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:processId] = process_id
          @attributes[:clientInfo] = client_info if client_info
          @attributes[:locale] = locale if locale
          @attributes[:rootPath] = root_path if root_path
          @attributes[:rootUri] = root_uri
          @attributes[:initializationOptions] = initialization_options if initialization_options
          @attributes[:capabilities] = capabilities
          @attributes[:trace] = trace if trace
          @attributes[:workspaceFolders] = workspace_folders if workspace_folders

          @attributes.freeze
        end

        #
        # An optional token that a server can use to report work done progress.
        #
        # @return [ProgressToken]
        def work_done_token
          attributes.fetch(:workDoneToken)
        end

        #
        # The process Id of the parent process that started the server. Is null if
        # the process has not been started by another process. If the parent
        # process is not alive then the server should exit (see exit notification)
        # its process.
        #
        # @return [number]
        def process_id
          attributes.fetch(:processId)
        end

        #
        # Information about the client
        #
        # @return [{ name: string; version?: string; }]
        def client_info
          attributes.fetch(:clientInfo)
        end

        #
        # The locale the client is currently showing the user interface
        # in. This must not necessarily be the locale of the operating
        # system.
        #
        # Uses IETF language tags as the value's syntax
        # (See https://en.wikipedia.org/wiki/IETF_language_tag)
        #
        # @return [string]
        def locale
          attributes.fetch(:locale)
        end

        #
        # The rootPath of the workspace. Is null
        # if no folder is open.
        #
        # @return [string]
        def root_path
          attributes.fetch(:rootPath)
        end

        #
        # The rootUri of the workspace. Is null if no
        # folder is open. If both `rootPath` and `rootUri` are set
        # `rootUri` wins.
        #
        # @return [string]
        def root_uri
          attributes.fetch(:rootUri)
        end

        #
        # User provided initialization options.
        #
        # @return [LSPAny]
        def initialization_options
          attributes.fetch(:initializationOptions)
        end

        #
        # The capabilities provided by the client (editor or tool)
        #
        # @return [ClientCapabilities]
        def capabilities
          attributes.fetch(:capabilities)
        end

        #
        # The initial trace setting. If omitted trace is disabled ('off').
        #
        # @return [TraceValue]
        def trace
          attributes.fetch(:trace)
        end

        #
        # The workspace folders configured in the client when the server starts.
        # This property is only available if the client supports workspace folders.
        # It can be `null` if the client supports workspace folders but none are
        # configured.
        #
        # @return [WorkspaceFolder[]]
        def workspace_folders
          attributes.fetch(:workspaceFolders)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
