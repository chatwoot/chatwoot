# typed: strict
# frozen_string_literal: true

require "hash_diff"

module ShopifyAPI
  module Utils
    module AttributesComparator
      class << self
        extend T::Sig

        sig do
          params(
            original_attributes: T::Hash[String, T.untyped],
            updated_attributes: T::Hash[String, T.untyped],
            atomic_hash_attributes: T::Array[Symbol],
          ).returns(T::Hash[String, T.untyped])
        end
        def compare(original_attributes, updated_attributes, atomic_hash_attributes: [])
          attributes_diff = HashDiff::Comparison.new(
            original_attributes,
            updated_attributes,
          ).left_diff

          update_value = build_update_value(
            attributes_diff,
            reference_values: updated_attributes,
            atomic_hash_attributes: atomic_hash_attributes,
          )

          update_value
        end

        sig do
          params(
            diff: T::Hash[String, T.untyped],
            path: T::Array[String],
            reference_values: T::Hash[String, T.untyped],
            atomic_hash_attributes: T::Array[Symbol],
          ).returns(T::Hash[String, T.untyped])
        end
        def build_update_value(diff, path: [], reference_values: {}, atomic_hash_attributes: [])
          new_hash = {}

          diff.each do |key, value|
            current_path = path + [key.to_s]

            if value.is_a?(Hash)
              has_numbered_key = value.keys.any? { |k| k.is_a?(Integer) }
              ref_value = T.unsafe(reference_values).dig(*current_path)

              if has_numbered_key && ref_value.is_a?(Array)
                new_hash[key] = ref_value
              else
                new_value = build_update_value(
                  value,
                  path: current_path,
                  reference_values: reference_values,
                  atomic_hash_attributes: atomic_hash_attributes,
                )

                atomic_update = atomic_hash_attributes.include?(key.to_sym)

                # If the key is in atomic_hash_attributes, we use the entire reference value
                # so we update the hash as a whole.
                if !new_value.empty? && !ref_value.empty? && atomic_update
                  new_hash[key] = ref_value

                # Only add to new_hash if the user intentionally updates
                # to empty value like `{}` or `[]`. For example:
                #
                # original = { "a" => { "foo" => 1 } }
                # updated = { "a" => {} }
                # diff = { "a" => { "foo" => HashDiff::NO_VALUE } }
                # key = "a", new_value = {}, ref_value = {}
                # new_hash = { "a" => {} }
                #
                # In addition, we omit cases where after removing `HashDiff::NO_VALUE`
                # we only have `{}` left. For example:
                #
                # original = { "a" => { "foo" => 1, "bar" => 2} }
                # updated = { "a" => { "foo" => 1 } }
                # diff = { "a" => { "bar" => HashDiff::NO_VALUE } }
                # key = "a", new_value = {}, ref_value = { "foo" => 1 }
                # new_hash = {}
                #
                # new_hash is empty because nothing changes
                elsif !new_value.empty? || ref_value.empty?
                  new_hash[key] = new_value
                end
              end
            elsif value != HashDiff::NO_VALUE
              new_hash[key] = value
            end
          end

          new_hash
        end
      end
    end
  end
end
