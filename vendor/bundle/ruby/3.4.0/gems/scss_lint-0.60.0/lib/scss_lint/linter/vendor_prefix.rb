module SCSSLint
  # Checks for vendor prefixes.
  class Linter::VendorPrefix < Linter
    include LinterRegistry

    def visit_root(_node)
      @identifiers = Set.new(extract_identifiers_from_config)
      @identifiers.merge(Set.new(config['additional_identifiers']))
      @exclusions = Set.new(config['excluded_identifiers'])
      yield
    end

    def check_node(node)
      name = node.name.is_a?(Array) ? node.name.join : node.name
      # Ignore '@' from @keyframes node name
      check_identifier(node, name.sub(/^@/, ''))

      # Check for values
      return unless node.respond_to?(:value) && node.value.first.respond_to?(:source_range)
      check_identifier(node, source_from_range(node.value.first.source_range))
    end

    alias visit_prop check_node
    alias visit_pseudo check_node
    alias visit_directive check_node

  private

    def check_identifier(node, identifier)
      return unless identifier.match?(/^[_-]/)

      # Strip vendor prefix to check against identifiers.
      # (Also strip closing parentheticals from values like linear-gradient.)
      stripped_identifier = identifier.gsub(/(^[_-][a-zA-Z0-9_]+-|\(.*\)|;)/, '').strip
      return if @exclusions.include?(stripped_identifier)
      return unless @identifiers.include?(stripped_identifier)

      add_lint(node, 'Avoid vendor prefixes.')
    end

    def extract_identifiers_from_config
      case config['identifier_list']
      when nil
        nil
      when Array
        config['identifier_list']
      when String
        begin
          file = File.open(File.join(SCSS_LINT_DATA,
                                     'prefixed-identifiers',
                                     "#{config['identifier_list']}.txt"))
          file.read.split("\n").reject { |line| line =~ /^(#|\s*$)/ }
        rescue Errno::ENOENT
          raise SCSSLint::Exceptions::LinterError,
                "Identifier list '#{config['identifier_list']}' does not exist"
        end
      else
        raise SCSSLint::Exceptions::LinterError,
              'Invalid identifier list specified -- must be the name of a '\
              'preset or an array of strings'
      end
    end
  end
end
