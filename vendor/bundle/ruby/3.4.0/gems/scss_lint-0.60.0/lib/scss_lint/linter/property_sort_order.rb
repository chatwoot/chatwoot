module SCSSLint
  # Checks the declaration order of properties.
  class Linter::PropertySortOrder < Linter # rubocop:disable ClassLength
    include LinterRegistry

    def visit_root(_node)
      @preferred_order = extract_preferred_order_from_config

      if @preferred_order && config['separate_groups']
        @group = assign_groups(@preferred_order)
      end

      yield # Continue linting children
    end

    def check_order(node)
      sortable_props = node.children.select do |child|
        child.is_a?(Sass::Tree::PropNode) && !ignore_property?(child)
      end

      if sortable_props.count >= config.fetch('min_properties', 2)
        sortable_prop_info =
          sortable_props.map do |child|
            name = child.name.join
            /^(?<vendor>-\w+(-osx)?-)?(?<property>.+)/ =~ name
            { name: name, vendor: vendor, property: "#{@nested_under}#{property}", node: child }
          end

        check_sort_order(sortable_prop_info)
        check_group_separation(sortable_prop_info) if @group
      end

      yield # Continue linting children
    end

    alias visit_media check_order
    alias visit_mixin check_order
    alias visit_rule check_order

    def visit_prop(node, &block)
      # Handle nested properties by appending the parent property they are
      # nested under to the name
      @nested_under = "#{node.name.join}-"
      check_order(node, &block)
      @nested_under = nil
    end

    def visit_if(node, &block)
      check_order(node, &block)
      visit(node.else) if node.else
    end

  private

    # When enforcing whether a blank line should separate "groups" of
    # properties, we need to assign those properties to group numbers so we can
    # quickly tell traversing from one property to the other that a blank line
    # is required (since the group number would change).
    def assign_groups(order)
      group_number = 0
      last_was_empty = false

      order.each_with_object({}) do |property, group|
        # A gap indicates the start of the next group
        if property.nil? || property.strip.empty?
          group_number += 1 unless last_was_empty # Treat multiple gaps as single gap
          last_was_empty = true
          next
        end

        last_was_empty = false

        group[property] = group_number
      end
    end

    def check_sort_order(sortable_prop_info)
      sortable_prop_info = sortable_prop_info.uniq { |item| item[:name] }
      sorted_props = sortable_prop_info.sort { |a, b| compare_properties(a, b) }

      sorted_props.each_with_index do |prop, index|
        # Once we reach the portion of the list with unspecified properties, we
        # can stop checking since we don't care about order after that point
        break unless specified_property?(prop[:property])

        next unless prop != sortable_prop_info[index]

        add_lint(sortable_prop_info[index][:node], lint_message(sorted_props))
        break
      end
    end

    def check_group_separation(sortable_prop_info) # rubocop:disable AbcSize
      group_number = @group[sortable_prop_info.first[:property]]

      sortable_prop_info[0..-2].zip(sortable_prop_info[1..-1]).each do |first, second|
        next unless @group[second[:property]] != group_number

        # We're now in the next group
        group_number = @group[second[:property]]

        # The group number has changed, so ensure this property is separated
        # from the previous property by at least a line (could be a comment,
        # we don't care, but at least one line that isn't another property).
        next if first[:node].line < second[:node].line - 1

        add_lint second[:node], "Property `#{second[:name]}` should have an " \
                                'empty line separating it from the previous ' \
                                "group of properties ending with `#{first[:name]}`"
      end
    end

    # Compares two properties which can contain a vendor prefix. It allows for a
    # sort order like:
    #
    #   p {
    #     border: ...
    #     -moz-border-radius: ...
    #     -o-border-radius: ...
    #     -webkit-border-radius: ...
    #     border-radius: ...
    #     color: ...
    #   }
    #
    # ...where vendor-prefixed properties come before the standard property, and
    # are ordered amongst themselves by vendor prefix.
    def compare_properties(a, b)
      if a[:property] == b[:property]
        compare_by_vendor(a, b)
      elsif @preferred_order
        compare_by_order(a, b, @preferred_order)
      else
        a[:property] <=> b[:property]
      end
    end

    def compare_by_vendor(a, b)
      if a[:vendor] && b[:vendor]
        a[:vendor] <=> b[:vendor]
      elsif a[:vendor]
        -1
      elsif b[:vendor]
        1
      else
        0
      end
    end

    def compare_by_order(a, b, order)
      (order.index(a[:property]) || Float::INFINITY) <=>
        (order.index(b[:property]) || Float::INFINITY)
    end

    def extract_preferred_order_from_config
      case config['order']
      when nil
        nil # No custom order specified
      when Array
        config['order']
      when String
        begin
          file = File.open(File.join(SCSS_LINT_DATA,
                                     'property-sort-orders',
                                     "#{config['order']}.txt"))
          file.read.split("\n").reject { |line| line =~ /^\s*#/ }
        rescue Errno::ENOENT
          raise SCSSLint::Exceptions::LinterError,
                "Preset property sort order '#{config['order']}' does not exist"
        end
      else
        raise SCSSLint::Exceptions::LinterError,
              'Invalid property sort order specified -- must be the name of a '\
              'preset or an array of strings'
      end
    end

    # Return whether to ignore a property in the sort order.
    #
    # This includes:
    # - properties containing interpolation
    # - properties not explicitly defined in the sort order (if ignore_unspecified is set)
    def ignore_property?(prop_node)
      return true if prop_node.name.any? { |part| !part.is_a?(String) }

      config['ignore_unspecified'] &&
        @preferred_order &&
        !@preferred_order.include?(prop_node.name.join)
    end

    def specified_property?(prop_name)
      !@preferred_order || @preferred_order.include?(prop_name)
    end

    def preset_order?
      config['order'].is_a?(String)
    end

    def lint_message(sortable_prop_info)
      props = sortable_prop_info.map { |prop| prop[:name] }.join(', ')
      "Properties should be ordered #{props}"
    end
  end
end
