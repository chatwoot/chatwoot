# frozen_string_literal: true

module Rails
  module Dom
    module Testing
      module Assertions
        module DomAssertions
          # \Test two HTML strings for equivalency (e.g., equal even when attributes are in another order)
          #
          #   # assert that the referenced method generates the appropriate HTML string
          #   assert_dom_equal(
          #     '<a href="http://www.example.com">Apples</a>',
          #     link_to("Apples", "http://www.example.com"),
          #   )
          #
          # By default, the matcher will not pay attention to whitespace in text nodes (e.g., spaces
          # and newlines). If you want stricter matching with exact matching for whitespace, pass
          # <tt>strict: true</tt>:
          #
          #   # these assertions will both pass
          #   assert_dom_equal     "<div>\nfoo\n\</div>", "<div>foo</div>", strict: false
          #   assert_dom_not_equal "<div>\nfoo\n\</div>", "<div>foo</div>", strict: true
          #
          # The DOMs are created using an HTML parser specified by
          # Rails::Dom::Testing.default_html_version (either :html4 or :html5).
          #
          # When testing in a Rails application, the parser default can also be set by setting
          # +Rails.application.config.dom_testing_default_html_version+.
          #
          # If you want to specify the HTML parser just for a particular assertion, pass
          # <tt>html_version: :html4</tt> or <tt>html_version: :html5</tt> keyword arguments:
          #
          #   assert_dom_equal expected, actual, html_version: :html5
          #
          def assert_dom_equal(expected, actual, message = nil, strict: false, html_version: nil)
            expected_dom, actual_dom = fragment(expected, html_version: html_version), fragment(actual, html_version: html_version)
            message ||= "Expected: #{expected}\nActual: #{actual}"
            assert compare_doms(expected_dom, actual_dom, strict), message
          end

          # The negated form of +assert_dom_equal+.
          #
          #   # assert that the referenced method does not generate the specified HTML string
          #   assert_dom_not_equal(
          #     '<a href="http://www.example.com">Apples</a>',
          #     link_to("Oranges", "http://www.example.com"),
          #   )
          #
          # By default, the matcher will not pay attention to whitespace in text nodes (e.g., spaces
          # and newlines). If you want stricter matching with exact matching for whitespace, pass
          # <tt>strict: true</tt>:
          #
          #   # these assertions will both pass
          #   assert_dom_equal     "<div>\nfoo\n\</div>", "<div>foo</div>", strict: false
          #   assert_dom_not_equal "<div>\nfoo\n\</div>", "<div>foo</div>", strict: true
          #
          # The DOMs are created using an HTML parser specified by
          # Rails::Dom::Testing.default_html_version (either :html4 or :html5).
          #
          # When testing in a Rails application, the parser default can also be set by setting
          # +Rails.application.config.dom_testing_default_html_version+.
          #
          # If you want to specify the HTML parser just for a particular assertion, pass
          # <tt>html_version: :html4</tt> or <tt>html_version: :html5</tt> keyword arguments:
          #
          #   assert_dom_not_equal expected, actual, html_version: :html5
          #
          def assert_dom_not_equal(expected, actual, message = nil, strict: false, html_version: nil)
            expected_dom, actual_dom = fragment(expected, html_version: html_version), fragment(actual, html_version: html_version)
            message ||= "Expected: #{expected}\nActual: #{actual}"
            assert_not compare_doms(expected_dom, actual_dom, strict), message
          end

          protected
            def compare_doms(expected, actual, strict)
              expected_children = extract_children(expected, strict)
              actual_children   = extract_children(actual, strict)
              return false unless expected_children.size == actual_children.size

              expected_children.each_with_index do |child, i|
                return false unless equal_children?(child, actual_children[i], strict)
              end

              true
            end

            def extract_children(node, strict)
              if strict
                node.children
              else
                node.children.reject { |n| n.text? && n.text.blank? }
              end
            end

            def equal_children?(child, other_child, strict)
              return false unless child.type == other_child.type

              if child.element?
                child.name == other_child.name &&
                    equal_attribute_nodes?(child.attribute_nodes, other_child.attribute_nodes) &&
                    compare_doms(child, other_child, strict)
              else
                equal_child?(child, other_child, strict)
              end
            end

            def equal_child?(child, other_child, strict)
              if strict
                child.to_s == other_child.to_s
              else
                child.to_s.split == other_child.to_s.split
              end
            end

            def equal_attribute_nodes?(nodes, other_nodes)
              return false unless nodes.size == other_nodes.size

              nodes = nodes.sort_by(&:name)
              other_nodes = other_nodes.sort_by(&:name)

              nodes.each_with_index do |attr, i|
                return false unless equal_attribute?(attr, other_nodes[i])
              end

              true
            end

            def equal_attribute?(attr, other_attr)
              attr.name == other_attr.name && attr.value == other_attr.value
            end

          private
            def fragment(text, html_version: nil)
              Rails::Dom::Testing.html_document_fragment(html_version: html_version).parse(text)
            end
        end
      end
    end
  end
end
