module ReverseMarkdown
    module Converters
      class Details < Base
        def convert(node, state = {})
          content = treat_children(node, state.merge(already_processed: true))
          if disabled? || content.strip.empty? || state[:already_processed]
            content
          else
            "##{content}"
          end
        end

        def enabled?
          ReverseMarkdown.config.github_flavored
        end

        def disabled?
          !enabled?
        end
      end

      register :details, Details.new
      register :summary, Details.new
    end
end
