module Sprockets
  module Rails
    # Rewrites source mapping urls with the digested paths and protect against semicolon appending with a dummy comment line
    class SourcemappingUrlProcessor
      REGEX = /\/\/# sourceMappingURL=(.*\.map)/

      class << self
        def call(input)
          env     = input[:environment]
          context = env.context_class.new(input)
          data    = input[:data].gsub(REGEX) do |_match|
            sourcemap_logical_path = combine_sourcemap_logical_path(sourcefile: input[:name], sourcemap: $1)

            begin
              resolved_sourcemap_comment(sourcemap_logical_path, context: context)
            rescue Sprockets::FileNotFound
              removed_sourcemap_comment(sourcemap_logical_path, filename: input[:filename], env: env)
            end
          end

          { data: data }
        end

        private
          def combine_sourcemap_logical_path(sourcefile:, sourcemap:)
            if (parts = sourcefile.split("/")).many?
              parts[0..-2].append(sourcemap).join("/")
            else
              sourcemap
            end
          end

          def resolved_sourcemap_comment(sourcemap_logical_path, context:)
            "//# sourceMappingURL=#{sourcemap_asset_path(sourcemap_logical_path, context: context)}\n//!\n"
          end

          def sourcemap_asset_path(sourcemap_logical_path, context:)
            # FIXME: Work-around for bug where if the sourcemap is nested two levels deep, it'll resolve as the source file
            # that's being mapped, rather than the map itself. So context.resolve("a/b/c.js.map") will return "c.js?"
            if context.resolve(sourcemap_logical_path) =~ /\.map/
              context.asset_path(sourcemap_logical_path)
            else
              raise Sprockets::FileNotFound, "Failed to resolve source map asset due to nesting depth"
            end
          end

          def removed_sourcemap_comment(sourcemap_logical_path, filename:, env:)
            env.logger.warn "Removed sourceMappingURL comment for missing asset '#{sourcemap_logical_path}' from #{filename}"
            nil
          end
      end
    end
  end
end
