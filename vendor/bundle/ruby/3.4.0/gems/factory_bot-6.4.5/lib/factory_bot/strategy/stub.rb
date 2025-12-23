module FactoryBot
  module Strategy
    class Stub
      @@next_id = 1000

      DISABLED_PERSISTENCE_METHODS = [
        :connection,
        :decrement!,
        :delete,
        :destroy!,
        :destroy,
        :increment!,
        :reload,
        :save!,
        :save,
        :toggle!,
        :touch,
        :update!,
        :update,
        :update_attribute,
        :update_attributes!,
        :update_attributes,
        :update_column,
        :update_columns
      ].freeze

      def self.next_id=(id)
        @@next_id = id
      end

      def association(runner)
        runner.run(:build_stubbed)
      end

      def result(evaluation)
        evaluation.object.tap do |instance|
          stub_database_interaction_on_result(instance)
          set_timestamps(instance)
          clear_changes_information(instance)
          evaluation.notify(:after_stub, instance)
        end
      end

      def to_sym
        :stub
      end

      private

      def next_id(result_instance)
        if uuid_primary_key?(result_instance)
          SecureRandom.uuid
        else
          @@next_id += 1
        end
      end

      def stub_database_interaction_on_result(result_instance)
        if has_settable_id?(result_instance)
          result_instance.id ||= next_id(result_instance)
        end

        result_instance.instance_eval do
          def persisted?
            true
          end

          def new_record?
            false
          end

          def destroyed?
            false
          end

          DISABLED_PERSISTENCE_METHODS.each do |write_method|
            define_singleton_method(write_method) do |*args|
              raise "stubbed models are not allowed to access the database - " \
                    "#{self.class}##{write_method}(#{args.join(",")})"
            end
          end
        end
      end

      def has_settable_id?(result_instance)
        result_instance.respond_to?(:id=) &&
          (!result_instance.class.respond_to?(:primary_key) ||
          result_instance.class.primary_key)
      end

      def uuid_primary_key?(result_instance)
        result_instance.respond_to?(:column_for_attribute) &&
          (column = result_instance.column_for_attribute(result_instance.class.primary_key)) &&
          column.respond_to?(:sql_type) &&
          column.sql_type == "uuid"
      end

      def clear_changes_information(result_instance)
        if result_instance.respond_to?(:clear_changes_information)
          result_instance.clear_changes_information
        end
      end

      def set_timestamps(result_instance)
        if missing_created_at?(result_instance)
          result_instance.created_at = Time.current
        end

        if missing_updated_at?(result_instance)
          result_instance.updated_at = Time.current
        end
      end

      def missing_created_at?(result_instance)
        result_instance.respond_to?(:created_at) &&
          result_instance.respond_to?(:created_at=) &&
          result_instance.created_at.blank?
      end

      def missing_updated_at?(result_instance)
        result_instance.respond_to?(:updated_at) &&
          result_instance.respond_to?(:updated_at=) &&
          result_instance.updated_at.blank?
      end
    end
  end
end
