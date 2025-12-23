module SafeYAML
  class Transform
    module TransformationMap
      def self.included(base)
        base.extend(ClassMethods)
      end

      class CaseAgnosticMap < Hash
        def initialize(*args)
          super
        end

        def include?(key)
          super(key.downcase)
        end

        def [](key)
          super(key.downcase)
        end

        # OK, I actually don't think it's all that important that this map be
        # frozen.
        def freeze
          self
        end
      end

      module ClassMethods
        def set_predefined_values(predefined_values)
          if SafeYAML::YAML_ENGINE == "syck"
            expanded_map = predefined_values.inject({}) do |hash, (key, value)|
              hash[key] = value
              hash[key.capitalize] = value
              hash[key.upcase] = value
              hash
            end
          else
            expanded_map = CaseAgnosticMap.new
            expanded_map.merge!(predefined_values)
          end

          self.const_set(:PREDEFINED_VALUES, expanded_map.freeze)
        end
      end
    end
  end
end
