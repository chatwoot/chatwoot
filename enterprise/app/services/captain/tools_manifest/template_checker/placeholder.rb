# Stands in for any variable a tool template can use: every lookup returns itself and loops over
# it are empty, so loop-local names are never evaluated. Branches that are not taken are not
# checked either.
class Captain::ToolsManifest::TemplateChecker::Placeholder < Liquid::Drop
  def liquid_method_missing(_name) = self

  def each(&) = [].each(&)

  def to_s = ''
end
