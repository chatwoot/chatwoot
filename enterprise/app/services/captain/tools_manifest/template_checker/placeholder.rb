# Stands in for any variable a tool template can use: every lookup returns itself and loops over it
# run once, so loop bodies are checked with the loop variable bound to another placeholder.
# Branches that are not taken (else, unless) are not checked; runtime errors surface those.
class Captain::ToolsManifest::TemplateChecker::Placeholder < Liquid::Drop
  def liquid_method_missing(_name) = self

  def each(&) = [self].each(&)

  def to_s = ''
end
