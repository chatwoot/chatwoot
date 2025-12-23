module Shoulda
  module Matchers
    module ActiveRecord
      # The `serialize` matcher tests usage of the `serialize` macro.
      #
      #     class Product < ActiveRecord::Base
      #       serialize :customizations
      #     end
      #
      #     # RSpec
      #     RSpec.describe Product, type: :model do
      #       it { should serialize(:customizations) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProductTest < ActiveSupport::TestCase
      #       should serialize(:customizations)
      #     end
      #
      # #### Qualifiers
      #
      # ##### as
      #
      # Use `as` if you are using a custom serializer class.
      #
      #     class ProductSpecsSerializer
      #       def load(string)
      #         # ...
      #       end
      #
      #       def dump(options)
      #         # ...
      #       end
      #     end
      #
      #     class Product < ActiveRecord::Base
      #       serialize :specifications, ProductSpecsSerializer
      #     end
      #
      #     # RSpec
      #     RSpec.describe Product, type: :model do
      #       it do
      #         should serialize(:specifications).
      #           as(ProductSpecsSerializer)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProductTest < ActiveSupport::TestCase
      #       should serialize(:specifications).
      #         as(ProductSpecsSerializer)
      #     end
      #
      # ##### as_instance_of
      #
      # Use `as_instance_of` if you are using a custom serializer object.
      #
      #     class ProductOptionsSerializer
      #       def load(string)
      #         # ...
      #       end
      #
      #       def dump(options)
      #         # ...
      #       end
      #     end
      #
      #     class Product < ActiveRecord::Base
      #       serialize :options, ProductOptionsSerializer.new
      #     end
      #
      #     # RSpec
      #     RSpec.describe Product, type: :model do
      #       it do
      #         should serialize(:options).
      #           as_instance_of(ProductOptionsSerializer)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProductTest < ActiveSupport::TestCase
      #       should serialize(:options).
      #         as_instance_of(ProductOptionsSerializer)
      #     end
      #
      # @return [SerializeMatcher]
      #
      def serialize(name)
        SerializeMatcher.new(name)
      end

      # @private
      class SerializeMatcher
        def initialize(name)
          @name = name.to_s
          @options = {}
        end

        def as(type)
          @options[:type] = type
          self
        end

        def as_instance_of(type)
          @options[:instance_type] = type
          self
        end

        def matches?(subject)
          @subject = subject
          serialization_valid? && type_valid?
        end

        def failure_message
          "Expected #{expectation} (#{@missing})"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        def description
          description = "serialize :#{@name}"
          if @options.key?(:type)
            description += " class_name => #{@options[:type]}"
          end
          description
        end

        protected

        def serialization_valid?
          if attribute_is_serialized?
            true
          else
            @missing = "no serialized attribute called :#{@name}"
            false
          end
        end

        def class_valid?
          if @options[:type]
            klass = serialization_coder
            if klass == @options[:type]
              true
            elsif klass.respond_to?(:object_class) &&
                  klass.object_class == @options[:type]
              true
            else
              @missing = ":#{@name} should be a type of #{@options[:type]}"
              false
            end
          else
            true
          end
        end

        def model_class
          @subject.class
        end

        def instance_class_valid?
          if @options.key?(:instance_type)
            if serialization_coder.is_a?(@options[:instance_type])
              true
            else
              @missing = ":#{@name} should be an instance of #{@options[:type]}"
              false
            end
          else
            true
          end
        end

        def type_valid?
          class_valid? && instance_class_valid?
        end

        def expectation
          expectation = "#{model_class.name} to serialize the attribute called"\
            " :#{@name}"
          expectation += " with a type of #{@options[:type]}" if @options[:type]
          if @options[:instance_type]
            expectation += " with an instance of #{@options[:instance_type]}"
          end
          expectation
        end

        def attribute_is_serialized?
          !!serialization_coder
        end

        def serialization_coder
          RailsShim.attribute_serialization_coder_for(model, @name)
        end

        def model
          @subject.class
        end
      end
    end
  end
end
