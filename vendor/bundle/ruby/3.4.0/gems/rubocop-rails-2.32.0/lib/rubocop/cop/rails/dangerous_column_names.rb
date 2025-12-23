# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Avoid dangerous column names.
      #
      # Some column names are considered dangerous because they would overwrite methods already defined.
      #
      # @example
      #   # bad
      #   add_column :users, :save
      #
      #   # good
      #   add_column :users, :saved
      class DangerousColumnNames < Base # rubocop:disable Metrics/ClassLength
        include MigrationsHelper

        COLUMN_TYPE_METHOD_NAMES = %i[
          bigint
          binary
          blob
          boolean
          date
          datetime
          decimal
          float
          integer
          numeric
          primary_key
          string
          text
          time
        ].to_set.freeze

        # Generated from `ActiveRecord::AttributeMethods.dangerous_attribute_methods` on activerecord 7.1.3.
        # rubocop:disable Metrics/CollectionLiteralLength
        DANGEROUS_COLUMN_NAMES = %w[
          __callbacks
          __id__
          _assign_attribute
          _assign_attributes
          _before_commit_callbacks
          _commit_callbacks
          _committed_already_called
          _create_callbacks
          _create_record
          _delete_row
          _destroy
          _destroy_callbacks
          _ensure_no_duplicate_errors
          _find_callbacks
          _find_record
          _has_attribute
          _initialize_callbacks
          _lock_value_for_database
          _merge_attributes
          _primary_key_constraints_hash
          _raise_readonly_record_error
          _raise_record_not_destroyed
          _raise_record_not_touched_error
          _read_attribute
          _record_changed
          _reflections
          _rollback_callbacks
          _run_before_commit_callbacks
          _run_commit_callbacks
          _run_create_callbacks
          _run_destroy_callbacks
          _run_find_callbacks
          _run_initialize_callbacks
          _run_rollback_callbacks
          _run_save_callbacks
          _run_touch_callbacks
          _run_update_callbacks
          _run_validate_callbacks
          _run_validation_callbacks
          _save_callbacks
          _touch_callbacks
          _touch_row
          _trigger_destroy_callback
          _trigger_update_callback
          _update_callbacks
          _update_record
          _update_row
          _validate_callbacks
          _validation_callbacks
          _validators
          _write_attribute
          []
          []=
          accessed_fields
          add_to_transaction
          aggregate_reflections
          all_timestamp_attributes_in_model
          allow_destroy
          apply_scoping
          around_save_collection_association
          assign_attributes
          assign_multiparameter_attributes
          assign_nested_attributes_for_collection_association
          assign_nested_attributes_for_one_to_one_association
          assign_nested_parameter_attributes
          assign_to_or_mark_for_destruction
          associated_records_to_validate_or_save
          association
          association_cached
          association_foreign_key_changed
          association_instance_get
          association_instance_set
          association_valid
          attachment_changes
          attachment_reflections
          attribute
          attribute_aliases
          attribute_before_last_save
          attribute_before_type_cast
          attribute_came_from_user
          attribute_change
          attribute_change_to_be_saved
          attribute_changed
          attribute_changed_in_place
          attribute_for_database
          attribute_for_inspect
          attribute_in_database
          attribute_method
          attribute_method_matchers
          attribute_missing
          attribute_names
          attribute_names_for_partial_inserts
          attribute_names_for_partial_updates
          attribute_names_for_serialization
          attribute_present
          attribute_previous_change
          attribute_previously_changed
          attribute_previously_was
          attribute_was
          attribute_will_change
          attribute=
          attributes
          attributes_before_type_cast
          attributes_for_create
          attributes_for_database
          attributes_for_update
          attributes_in_database
          attributes_with_values
          attributes=
          automatic_scope_inversing
          becomes
          before_committed
          belongs_to_touch_method
          broadcast_action
          broadcast_action_later
          broadcast_action_later_to
          broadcast_action_to
          broadcast_after_to
          broadcast_append
          broadcast_append_later
          broadcast_append_later_to
          broadcast_append_to
          broadcast_before_to
          broadcast_prepend
          broadcast_prepend_later
          broadcast_prepend_later_to
          broadcast_prepend_to
          broadcast_remove
          broadcast_remove_to
          broadcast_render
          broadcast_render_later
          broadcast_render_later_to
          broadcast_render_to
          broadcast_rendering_with_defaults
          broadcast_replace
          broadcast_replace_later
          broadcast_replace_later_to
          broadcast_replace_to
          broadcast_target_default
          broadcast_update
          broadcast_update_later
          broadcast_update_later_to
          broadcast_update_to
          build_decrypt_attribute_assignments
          build_encrypt_attribute_assignments
          cache_key
          cache_key_with_version
          cache_timestamp_format
          cache_version
          cache_versioning
          call_reject_if
          can_use_fast_cache_version
          cant_modify_encrypted_attributes_when_frozen
          changed
          changed_attribute_names_to_save
          changed_attributes
          changed_for_autosave
          changes
          changes_applied
          changes_to_save
          check_record_limit
          ciphertext_for
          class
          clear_attribute_change
          clear_attribute_changes
          clear_changes_information
          clear_timestamp_attributes
          clear_transaction_record_state
          clone
          collection_cache_versioning
          column_for_attribute
          committed
          connection_handler
          create_or_update
          current_time_from_proper_timezone
          custom_inspect_method_defined
          custom_validation_context
          decrement
          decrypt
          decrypt_attributes
          decrypt_rich_texts
          default_connection_handler
          default_role
          default_scope_override
          default_scopes
          default_shard
          default_validation_context
          defined_enums
          delete
          destroy
          destroy_association_async_job
          destroy_associations
          destroy_row
          destroyed
          destroyed_by_association
          destroyed_by_association=
          dup
          each_counter_cached_associations
          encode_with
          encrypt
          encrypt_attributes
          encrypt_rich_texts
          encryptable_rich_texts
          encrypted_attribute
          encrypted_attributes
          encrypted_attributes=
          ensure_proper_type
          errors
          execute_callstack_for_multiparameter_attributes
          extract_callstack_for_multiparameter_attributes
          find_parameter_position
          forget_attribute_assignments
          format_for_inspect
          freeze
          from_json
          frozen?
          halted_callback_hook
          has_attribute
          has_changes_to_save
          has_defer_touch_attrs
          has_destroy_flag
          has_encrypted_attributes
          has_encrypted_rich_texts
          has_transactional_callbacks
          hash
          id
          id_before_type_cast
          id_for_database
          id_in_database
          id_was
          id=
          include_root_in_json
          increment
          init_internals
          init_with
          init_with_attributes
          initialize_internals_callback
          inspection_filter
          invalid
          lock
          lock_optimistically
          locking_enabled
          logger
          mark_for_destruction
          marked_for_destruction
          matched_attribute_method
          max_updated_column_timestamp
          missing_attribute
          model_name
          mutations_before_last_save
          mutations_from_database
          nested_attributes_options
          nested_records_changed_for_autosave
          new_record
          no_touching
          normalize_reflection_attribute
          partial_inserts
          partial_updates
          perform_validations
          persisted
          pk_attribute
          pluralize_table_names
          populate_with_current_scope_attributes
          previous_changes
          previously_new_record
          previously_persisted
          primary_key_prefix_type
          query_attribute
          raise_nested_attributes_record_not_found
          raise_validation_error
          raw_timestamp_to_cache_version
          read_attribute
          read_attribute_before_type_cast
          read_attribute_for_serialization
          read_attribute_for_validation
          read_store_attribute
          readonly
          record_timestamps
          record_timestamps=
          reject_new_record
          reload
          remember_transaction_record_state
          respond_to_without_attributes
          restore_attribute
          restore_attributes
          restore_transaction_record_state
          rolledback
          run_callbacks
          run_validations
          sanitize_for_mass_assignment
          sanitize_forbidden_attributes
          save
          save_belongs_to_association
          save_collection_association
          save_has_one_association
          saved_change_to_attribute
          saved_changes
          serializable_add_includes
          serializable_attributes
          serializable_hash
          should_record_timestamps
          signed_id
          signed_id_verifier_secret
          skip_time_zone_conversion_for_attributes
          slice
          store_accessor_for
          store_full_class_name
          store_full_sti_class
          strict_loaded_associations
          strict_loading
          strict_loading_mode
          strict_loading_n_plus_one_only
          surreptitiously_touch
          table_name_prefix
          table_name_suffix
          time_zone_aware_attributes
          time_zone_aware_types
          timestamp_attributes_for_create_in_model
          timestamp_attributes_for_update_in_model
          to_ary
          to_gid
          to_gid_param
          to_global_id
          to_key
          to_model
          to_partial_path
          to_sgid
          to_sgid_param
          to_signed_global_id
          toggle
          touch
          touch_deferred_attributes
          touch_later
          transaction
          transaction_include_any_action
          trigger_transactional_callbacks
          type_cast_attribute_value
          type_for_attribute
          update
          update_attribute
          update_column
          update_columns
          valid
          validate
          validate_collection_association
          validate_encryption_allowed
          validate_single_association
          validates_absence_of
          validates_acceptance_of
          validates_comparison_of
          validates_confirmation_of
          validates_exclusion_of
          validates_format_of
          validates_inclusion_of
          validates_length_of
          validates_numericality_of
          validates_presence_of
          validates_size_of
          validates_with
          validation_context
          validation_context=
          values_at
          verify_readonly_attribute
          will_be_destroyed
          will_save_change_to_attribute
          with_lock
          with_transaction_returning_status
          write_attribute
          write_store_attribute
        ].freeze
        # rubocop:enable Metrics/CollectionLiteralLength

        MSG = 'Avoid dangerous column names.'

        RESTRICT_ON_SEND = [:add_column, :rename, :rename_column, *COLUMN_TYPE_METHOD_NAMES].freeze

        def on_send(node)
          column_name_node = column_name_node_from(node)
          return false unless column_name_node
          return false unless dangerous_column_name_node?(column_name_node)

          add_offense(column_name_node)
        end

        private

        def column_name_node_from(node)
          case node.method_name
          when :add_column, :rename
            node.arguments[1]
          when :rename_column
            node.arguments[2]
          when *COLUMN_TYPE_METHOD_NAMES
            node.first_argument
          end
        end

        def dangerous_column_name_node?(node)
          return false unless node.respond_to?(:value)

          dangerous_column_name?(node.value.to_s)
        end

        def dangerous_column_name?(column_name)
          DANGEROUS_COLUMN_NAMES.include?(column_name)
        end
      end
    end
  end
end
