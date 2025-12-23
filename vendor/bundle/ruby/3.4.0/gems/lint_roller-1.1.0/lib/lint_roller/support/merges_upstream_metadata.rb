module LintRoller
  module Support
    class MergesUpstreamMetadata
      def merge(plugin_yaml, upstream_yaml)
        common_upstream_values = upstream_yaml.select { |key| plugin_yaml.key?(key) }

        plugin_yaml.merge(common_upstream_values) { |key, plugin_value, upstream_value|
          if plugin_value.is_a?(Hash) && upstream_value.is_a?(Hash)
            plugin_value.merge(upstream_value) { |sub_key, plugin_sub_value, upstream_sub_value|
              if plugin_value.key?(sub_key)
                plugin_sub_value
              else
                upstream_sub_value
              end
            }
          else
            plugin_value
          end
        }
      end
    end
  end
end
