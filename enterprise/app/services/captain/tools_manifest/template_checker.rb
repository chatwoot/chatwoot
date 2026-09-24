# Custom tools render their templates with strict Liquid at call time, so a syntax error, an
# undeclared variable or an unknown filter makes every call fail. This test-renders a template
# the same way, with a stand-in for each variable the tool will provide, to catch those upfront.
class Captain::ToolsManifest::TemplateChecker
  STRICT_ERRORS = [Liquid::UndefinedVariable, Liquid::UndefinedFilter].freeze

  # Returns a description of the first problem, or nil when the template renders cleanly
  def self.error_for(source, variables)
    template = Liquid::Template.parse(source, error_mode: :strict)
    template.render(variables.index_with { Placeholder.new }, strict_variables: true, strict_filters: true)
    error = template.errors.find { |candidate| STRICT_ERRORS.any? { |klass| candidate.is_a?(klass) } }
    "uses #{error.message.delete_prefix('Liquid error: ')}" if error
  rescue Liquid::SyntaxError => e
    "is not valid Liquid: #{e.message}"
  end
end
