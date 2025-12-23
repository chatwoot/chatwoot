# frozen_string_literal: true

module Rack

  # Rack middleware implementing the IETF draft: "Host Metadata for the Web"
  # including support for Link-Pattern elements as described in the IETF draft:
  # "Link-based Resource Descriptor Discovery."
  #
  # Usage:
  #  use Rack::HostMeta do
  #    link :uri => '/robots.txt', :rel => 'robots'
  #    link :uri => '/w3c/p3p.xml', :rel => 'privacy', :type => 'application/p3p.xml'
  #    link :pattern => '{uri};json_schema', :rel => 'describedby', :type => 'application/x-schema+json'
  #  end
  #
  # See also:
  #   http://tools.ietf.org/html/draft-nottingham-site-meta
  #   http://tools.ietf.org/html/draft-hammer-discovery
  #
  # TODO:
  #   Accept POST operations allowing downstream services to register themselves
  #
  class HostMeta
    def initialize(app, &block)
      @app = app
      @lines = []
      instance_eval(&block)
      @response = @lines.join("\n")
    end

    def call(env)
      if env['PATH_INFO'] == '/host-meta'
        [200, {'content-type' => 'application/host-meta'}, [@response]]
      else
        @app.call(env)
      end
    end

    protected

    def link(config)
      line = config[:uri] ? "Link: <#{config[:uri]}>;" : "Link-Pattern: <#{config[:pattern]}>;"
      fragments = []
      fragments << "rel=\"#{config[:rel]}\"" if config[:rel]
      fragments << "type=\"#{config[:type]}\"" if config[:type]
      @lines << "#{line} #{fragments.join("; ")}"
    end
  end
end
