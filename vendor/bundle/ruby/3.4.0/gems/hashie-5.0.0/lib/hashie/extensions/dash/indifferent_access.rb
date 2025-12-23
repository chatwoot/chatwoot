module Hashie
  module Extensions
    module Dash
      module IndifferentAccess
        def self.included(base)
          base.extend ClassMethods
          base.send :include, Hashie::Extensions::IndifferentAccess
        end

        def self.maybe_extend(base)
          return unless requires_class_methods?(base)

          base.extend(ClassMethods)
        end

        def self.requires_class_methods?(klass)
          klass <= Hashie::Dash &&
            !klass.singleton_class.included_modules.include?(ClassMethods)
        end
        private_class_method :requires_class_methods?

        def to_h
          defaults = ::Hash[self.class.properties.map do |prop|
            [Hashie::Extensions::IndifferentAccess.convert_key(prop), self.class.defaults[prop]]
          end]

          defaults.merge(self)
        end
        alias to_hash to_h

        module ClassMethods
          # Check to see if the specified property has already been
          # defined.
          def property?(name)
            name = translations[name.to_sym] if translation_for?(name)
            name = name.to_s
            !!properties.find { |property| property.to_s == name }
          end

          def translation_exists?(name)
            name = name.to_s
            !!translations.keys.find { |key| key.to_s == name }
          end

          def transformed_property(property_name, value)
            transform = transforms[property_name] || transforms[property_name.to_sym]
            transform.call(value)
          end

          def transformation_exists?(name)
            name = name.to_s
            !!transforms.keys.find { |key| key.to_s == name }
          end

          private

          def translation_for?(name)
            included_modules.include?(Hashie::Extensions::Dash::PropertyTranslation) &&
              translation_exists?(name)
          end
        end
      end
    end
  end
end
