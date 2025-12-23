require 'pathname'

module Brakeman
  module Codeclimate
    class EngineConfiguration

      def initialize(engine_config = {})
        @engine_config = engine_config
      end

      def options
        default_options.merge(configured_options)
      end

      private

      attr_reader :engine_config

      def default_options
        @default_options = {
          :output_format => :codeclimate,
          :quiet => true,
          :pager => false,
          :app_path => Dir.pwd
        }
        if system("test -w /dev/stdout")
          @default_options[:output_files] = ["/dev/stdout"]
        end
        @default_options
      end

      def configured_options
        @configured_options = {}
        # ATM this gets parsed as a string instead of bool: "config":{ "debug":"true" }
        if brakeman_configuration["debug"] && brakeman_configuration["debug"].to_s.downcase == "true"
          @configured_options[:debug] = true
          @configured_options[:report_progress] = false
        end

        if active_include_paths
          @configured_options[:only_files] = active_include_paths
        end

        if brakeman_configuration["app_path"]
          @configured_options[:path_prefix] = brakeman_configuration["app_path"]
          path = Pathname.new(Dir.pwd) + brakeman_configuration["app_path"]
          @configured_options[:app_path] = path.to_s
        end
        @configured_options
      end

      def brakeman_configuration
        if engine_config["config"]
          engine_config["config"]
        else
          {}
        end
      end

      def active_include_paths
        @active_include_paths ||=
          if brakeman_configuration["app_path"]
            stripped_include_paths(brakeman_configuration["app_path"])
          else
            engine_config["include_paths"] && engine_config["include_paths"].compact
          end
      end

      def stripped_include_paths(prefix)
        subprefixes = path_subprefixes(prefix)
        engine_config["include_paths"] && engine_config["include_paths"].map do |path|
          next unless path
          stripped_include_path(prefix, subprefixes, path)
        end.compact
      end

      def path_subprefixes(path)
        Pathname.new(path).each_filename.inject([]) do |memo, piece|
         memo <<
           if memo.any?
             File.join(memo.last, piece)
           else
             File.join(piece)
           end
        end
      end

      def stripped_include_path(prefix, subprefixes, path)
        if path.start_with?(prefix)
          path.sub(%r{^#{prefix}/?}, "/")
        elsif subprefixes.any? { |subprefix| path =~ %r{^#{subprefix}/?$} }
          "/"
        end
      end
    end
  end
end
