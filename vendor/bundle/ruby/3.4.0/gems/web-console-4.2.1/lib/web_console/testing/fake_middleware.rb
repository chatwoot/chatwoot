# frozen_string_literal: true

require "action_view"
require "action_dispatch" # This is needed to use Mime::Type
require "web_console"
require "web_console/testing/helper"

module WebConsole
  module Testing
    class FakeMiddleware
      I18n.load_path.concat(Dir[Helper.gem_root.join("lib/web_console/locales/*.yml")])

      DEFAULT_HEADERS = { Rack::CONTENT_TYPE => "application/javascript" }

      def initialize(opts)
        @headers        = opts.fetch(:headers, DEFAULT_HEADERS)
        @req_path_regex = opts[:req_path_regex]
        @view_path      = opts[:view_path]
      end

      def call(env)
        body = render(req_path(env))
        @headers[Rack::CONTENT_LENGTH] = body.bytesize.to_s

        [ 200, @headers, [ body ] ]
      end

      def view
        @view = View.with_empty_template_cache.with_view_paths(@view_path)
      end

      private

        # extract target path from REQUEST_PATH
        def req_path(env)
          File.basename(env["REQUEST_PATH"].match(@req_path_regex)[1], ".*")
        end

        def render(template)
          view.render(template: template, layout: nil)
        end
    end
  end
end
