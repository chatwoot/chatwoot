module SCSSLint
  # Checks for uses of properties where a Compass mixin would be preferred.
  class Linter::Compass::PropertyWithMixin < Linter::Compass
    include LinterRegistry

    def visit_prop(node)
      check_for_properties_with_mixins(node)
      check_for_inline_block(node)
    end

  private

    # Set of properties where the Compass mixin version is preferred
    PROPERTIES_WITH_MIXINS = %w[
      background-clip
      background-origin
      border-radius
      box-shadow
      box-sizing
      opacity
      text-shadow
      transform
    ].to_set

    def check_for_properties_with_mixins(node)
      prop_name = node.name.join
      return unless PROPERTIES_WITH_MIXINS.include?(prop_name) &&
                    !ignore_compass_mixin?(prop_name)

      add_lint node, "Use the Compass `#{prop_name}` mixin instead of the property"
    end

    def check_for_inline_block(node)
      prop_name = node.name.join
      return unless prop_name == 'display' &&
                    node.value.first.to_sass == 'inline-block' &&
                    !ignore_compass_mixin?('inline-block')

      add_lint node,
               'Use the Compass `inline-block` mixin instead of `display: inline-block`'
    end

    def ignore_compass_mixin?(prop_name)
      config.fetch('ignore', []).include?(prop_name)
    end
  end
end
