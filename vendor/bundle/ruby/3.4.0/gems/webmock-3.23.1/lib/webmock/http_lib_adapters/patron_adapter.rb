# frozen_string_literal: true

begin
  require 'patron'
rescue LoadError
  # patron not found
end

if defined?(::Patron)
  module WebMock
    module HttpLibAdapters
      class PatronAdapter < ::WebMock::HttpLibAdapter
        adapter_for :patron

        OriginalPatronSession = ::Patron::Session unless const_defined?(:OriginalPatronSession)

        class WebMockPatronSession < ::Patron::Session
          def handle_request(req)
            request_signature =
              WebMock::HttpLibAdapters::PatronAdapter.build_request_signature(req)

            WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

            if webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
              WebMock::HttpLibAdapters::PatronAdapter.
                handle_file_name(req, webmock_response)
              res = WebMock::HttpLibAdapters::PatronAdapter.
                build_patron_response(webmock_response, default_response_charset)
              WebMock::CallbackRegistry.invoke_callbacks(
                {lib: :patron}, request_signature, webmock_response)
              res
            elsif WebMock.net_connect_allowed?(request_signature.uri)
              res = super
              if WebMock::CallbackRegistry.any_callbacks?
                webmock_response = WebMock::HttpLibAdapters::PatronAdapter.
                  build_webmock_response(res)
                WebMock::CallbackRegistry.invoke_callbacks(
                  {lib: :patron, real_request: true}, request_signature,
                    webmock_response)
              end
              res
            else
              raise WebMock::NetConnectNotAllowedError.new(request_signature)
            end
          end
        end

        def self.enable!
          Patron.send(:remove_const, :Session)
          Patron.send(:const_set, :Session, WebMockPatronSession)
        end

        def self.disable!
          Patron.send(:remove_const, :Session)
          Patron.send(:const_set, :Session, OriginalPatronSession)
        end

        def self.handle_file_name(req, webmock_response)
          if req.action == :get && req.file_name
            begin
              File.open(req.file_name, "w") do |f|
                f.write webmock_response.body
              end
            rescue Errno::EACCES
              raise ArgumentError.new("Unable to open specified file.")
            end
          end
        end

        def self.build_request_signature(req)
          uri = WebMock::Util::URI.heuristic_parse(req.url)
          uri.path = uri.normalized_path.gsub("[^:]//","/")

          if [:put, :post, :patch].include?(req.action)
            if req.file_name
              if !File.exist?(req.file_name) || !File.readable?(req.file_name)
                raise ArgumentError.new("Unable to open specified file.")
              end
              request_body = File.read(req.file_name)
            elsif req.upload_data
              request_body = req.upload_data
            else
              raise ArgumentError.new("Must provide either data or a filename when doing a PUT or POST")
            end
          end

          headers = req.headers

          if req.credentials
            headers['Authorization'] = WebMock::Util::Headers.basic_auth_header(req.credentials)
          end

          request_signature = WebMock::RequestSignature.new(
            req.action,
            uri.to_s,
            body: request_body,
            headers: headers
          )
          request_signature
        end

        def self.build_patron_response(webmock_response, default_response_charset)
          raise ::Patron::TimeoutError if webmock_response.should_timeout
          webmock_response.raise_error_if_any

          header_fields = (webmock_response.headers || []).map { |(k, vs)| Array(vs).map { |v| "#{k}: #{v}" } }.flatten
          status_line   = "HTTP/1.1 #{webmock_response.status[0]} #{webmock_response.status[1]}"
          header_data   = ([status_line] + header_fields).join("\r\n")

          ::Patron::Response.new(
            "".dup,
            webmock_response.status[0],
            0,
            header_data,
            webmock_response.body.dup,
            default_response_charset
          )
        end

        def self.build_webmock_response(patron_response)
          webmock_response = WebMock::Response.new
          reason = patron_response.status_line.
            scan(%r(\AHTTP/(\d+(?:\.\d+)?)\s+(\d\d\d)\s*([^\r\n]+)?))[0][2]
          webmock_response.status = [patron_response.status, reason]
          webmock_response.body = patron_response.body
          webmock_response.headers = patron_response.headers
          webmock_response
        end
      end
    end
  end
end
