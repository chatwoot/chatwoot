module Shoulda
  module Matchers
    module ActiveRecord
      # @private
      module Uniqueness
        # @private
        class TestModelCreator
          def self.create(model_name, namespace)
            Mutex.new.synchronize do
              new(model_name, namespace).create
            end
          end

          def initialize(model_name, namespace)
            @model_name = model_name
            @namespace = namespace
          end

          def create
            new_model.tap do |new_model|
              new_model.symlink_to(existing_model)
            end
          end

          protected

          attr_reader :model_name, :namespace

          private

          def model_name_without_namespace
            model_name.demodulize
          end

          def new_model
            @_new_model ||= Model.next_unique_copy_of(
              model_name_without_namespace,
              namespace,
            )
          end

          def existing_model
            @_existing_model ||= model_name.constantize
          end
        end
      end
    end
  end
end
