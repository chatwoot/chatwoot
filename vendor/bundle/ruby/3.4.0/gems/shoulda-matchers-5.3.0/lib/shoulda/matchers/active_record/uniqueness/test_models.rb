module Shoulda
  module Matchers
    module ActiveRecord
      # @private
      module Uniqueness
        # @private
        module TestModels
          def self.create(model_name)
            TestModelCreator.create(model_name, root_namespace)
          end

          def self.remove_all
            root_namespace.clear
          end

          def self.root_namespace
            @_root_namespace ||= Namespace.new(self)
          end
        end
      end
    end
  end
end
