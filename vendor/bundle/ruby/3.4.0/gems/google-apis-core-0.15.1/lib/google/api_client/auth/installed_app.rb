# Copyright 2010 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'webrick'

launchy_available =
  begin
    require 'launchy'
    true
  rescue LoadError
    warn "Attempted to require google/api_client/auth/installed_app.rb when" \
         " launchy is not available. The InstalledAppFlow class is disabled."
    false
  end

module Google
  class APIClient

    # Small helper for the sample apps for performing OAuth 2.0 flows from the command
    # line or in any other installed app environment.
    #
    # This class is used in some sample apps and tests but is not really part
    # of the client libraries, and probably does not belong here. As such, it
    # is deprecated. If you do choose to use it, note that you must include the
    # `launchy` gem in your bundle, as it is required by this class but not
    # listed in the google-api-client gem's requirements.
    #
    # @example
    #
    #    flow = Google::APIClient::InstalledAppFlow.new(
    #      :client_id => '691380668085.apps.googleusercontent.com',
    #      :client_secret => '...',
    #      :scope => 'https://www.googleapis.com/auth/drive'
    #    )
    #    authorization = flow.authorize
    #    Drive = Google::Apis::DriveV2
    #    drive = Drive::DriveService.new
    #    drive.authorization = authorization
    #
    # @deprecated Use google-auth-library-ruby instead
    class InstalledAppFlow

      RESPONSE_BODY = <<-HTML
        <html>
          <head>
            <script>
              function closeWindow() {
                window.open('', '_self', '');
                window.close();
              }
              setTimeout(closeWindow, 10);
            </script>
          </head>
          <body>You may close this window.</body>
        </html>
      HTML

      ##
      # Configure the flow
      #
      # @param [Hash] options The configuration parameters for the client.
      # @option options [Fixnum] :port
      #   Port to run the embedded server on. Defaults to 9292
      # @option options [String] :client_id
      #   A unique identifier issued to the client to identify itself to the
      #   authorization server.
      # @option options [String] :client_secret
      #   A shared symmetric secret issued by the authorization server,
      #   which is used to authenticate the client.
      # @option options [String] :scope
      #   The scope of the access request, expressed either as an Array
      #   or as a space-delimited String.
      #
      # @see Signet::OAuth2::Client
      def initialize(options)
        @port = options[:port] || 9292
        @authorization = Signet::OAuth2::Client.new({
          :authorization_uri => 'https://accounts.google.com/o/oauth2/auth',
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :redirect_uri => "http://localhost:#{@port}/"}.update(options)
        )
      end

      ##
      # Request authorization. Opens a browser and waits for response.
      #
      # @param [Google::APIClient::Storage] storage
      #  Optional object that responds to :write_credentials, used to serialize
      #  the OAuth 2 credentials after completing the flow.
      #
      # @return [Signet::OAuth2::Client]
      #  Authorization instance, nil if user cancelled.
      def authorize(storage=nil, options={})
        auth = @authorization

        server = WEBrick::HTTPServer.new(
          :Port => @port,
          :BindAddress =>"localhost",
          :Logger => WEBrick::Log.new(STDOUT, 0),
          :AccessLog => []
        )
        begin
          trap("INT") { server.shutdown }

          server.mount_proc '/' do |req, res|
            auth.code = req.query['code']
            if auth.code
              auth.fetch_access_token!
            end
            res.status = WEBrick::HTTPStatus::RC_ACCEPTED
            res.body = RESPONSE_BODY
            server.stop
          end

          Launchy.open(auth.authorization_uri(options).to_s)
          server.start
        ensure
          server.shutdown
        end
        if @authorization.access_token
          if storage.respond_to?(:write_credentials)
            storage.write_credentials(@authorization)
          end
          return @authorization
        else
          return nil
        end
      end
    end

  end
end if launchy_available
