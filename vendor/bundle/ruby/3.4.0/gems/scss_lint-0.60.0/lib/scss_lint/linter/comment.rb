module SCSSLint
  # Checks for uses of renderable comments (/* ... */)
  class Linter::Comment < Linter
    include LinterRegistry

    def visit_comment(node)
      add_lint(node, message) unless valid_comment?(node)
    end

  private

    def valid_comment?(node)
      allowed_type =
        if config.fetch('style', 'silent') == 'silent'
          node.invisible?
        else
          !node.invisible?
        end
      return true if allowed_type

      # Otherwise check if comment contains content that excludes it (i.e. a
      # copyright notice for loud comments)
      allowed?(node)
    end

    # @param node [CommentNode]
    # @return [Boolean]
    def allowed?(node)
      return false unless config['allowed']
      re = Regexp.new(config['allowed'])

      node.value.join.match(re)
    end

    def message
      if config.fetch('style', 'silent') == 'silent'
        'Use `//` comments everywhere'
      else
        'Use `/* */` comments everywhere'
      end
    end
  end
end
