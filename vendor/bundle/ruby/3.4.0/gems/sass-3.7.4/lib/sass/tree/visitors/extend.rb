# A visitor for performing selector inheritance on a static CSS tree.
#
# Destructively modifies the tree.
class Sass::Tree::Visitors::Extend < Sass::Tree::Visitors::Base
  # Performs the given extensions on the static CSS tree based in `root`, then
  # validates that all extends matched some selector.
  #
  # @param root [Tree::Node] The root node of the tree to visit.
  # @param extends [Sass::Util::SubsetMap{Selector::Simple =>
  #                                       Sass::Tree::Visitors::Cssize::Extend}]
  #   The extensions to perform on this tree.
  # @return [Object] The return value of \{#visit} for the root node.
  def self.visit(root, extends)
    return if extends.empty?
    new(extends).send(:visit, root)
    check_extends_fired! extends
  end

  protected

  def initialize(extends)
    @parent_directives = []
    @extends = extends
  end

  # If an exception is raised, this adds proper metadata to the backtrace.
  def visit(node)
    super(node)
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  # Keeps track of the current parent directives.
  def visit_children(parent)
    @parent_directives.push parent if parent.is_a?(Sass::Tree::DirectiveNode)
    super
  ensure
    @parent_directives.pop if parent.is_a?(Sass::Tree::DirectiveNode)
  end

  # Applies the extend to a single rule's selector.
  def visit_rule(node)
    node.resolved_rules = node.resolved_rules.do_extend(@extends, @parent_directives)
  end

  class << self
    private

    def check_extends_fired!(extends)
      extends.each_value do |ex|
        next if ex.success || ex.node.optional?
        message = "\"#{ex.extender}\" failed to @extend \"#{ex.target.join}\"."

        # TODO(nweiz): this should use the Sass stack trace of the extend node.
        raise Sass::SyntaxError.new(<<MESSAGE, :filename => ex.node.filename, :line => ex.node.line)
#{message}
The selector "#{ex.target.join}" was not found.
Use "@extend #{ex.target.join} !optional" if the extend should be able to fail.
MESSAGE
      end
    end
  end
end
