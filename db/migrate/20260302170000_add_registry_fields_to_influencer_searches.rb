require 'digest'

# rubocop:disable Style/OneClassPerFile
class AddRegistryFieldsToInfluencerSearches < ActiveRecord::Migration[7.0]
  class MigrationInfluencerSearch < ApplicationRecord
    self.table_name = 'influencer_searches'
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def up
    add_column :influencer_searches, :query_signature, :string
    add_column :influencer_searches, :page_size, :integer, default: 5, null: false
    add_column :influencer_searches, :pages_fetched, :integer, default: 0, null: false
    add_column :influencer_searches, :last_credits_left, :float

    MigrationInfluencerSearch.reset_column_information

    MigrationInfluencerSearch.find_each do |search|
      normalized_params = normalize_hash(search.query_params || {})
      pages_fetched = if Array(search.results).empty? && search.results_count.to_i.zero?
                        0
                      else
                        (Array(search.results).size.to_f / 5).ceil
                      end

      # rubocop:disable Rails/SkipsModelValidations
      search.update_columns(
        query_params: normalized_params,
        query_signature: Digest::SHA256.hexdigest(JSON.generate(normalized_params)),
        page_size: 5,
        pages_fetched: pages_fetched
      )
      # rubocop:enable Rails/SkipsModelValidations
    end

    deduplicate_searches!

    change_column_null :influencer_searches, :query_signature, false
    add_index :influencer_searches, %i[account_id query_signature], unique: true
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def down
    remove_index :influencer_searches, column: %i[account_id query_signature]
    remove_column :influencer_searches, :last_credits_left
    remove_column :influencer_searches, :pages_fetched
    remove_column :influencer_searches, :page_size
    remove_column :influencer_searches, :query_signature
  end

  private

  def deduplicate_searches!
    duplicate_ids = select_values(<<~SQL.squish)
      SELECT id
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY account_id, query_signature
                 ORDER BY created_at DESC, id DESC
               ) AS row_number
        FROM influencer_searches
      ) ranked_searches
      WHERE row_number > 1
    SQL

    return if duplicate_ids.empty?

    execute("DELETE FROM influencer_searches WHERE id IN (#{duplicate_ids.join(',')})")
  end

  def normalize_hash(value)
    value.to_h.each_with_object({}) do |(key, raw_value), normalized|
      normalized_value = normalize_value(raw_value)
      normalized[key.to_s] = normalized_value unless blank_value?(normalized_value)
    end.sort.to_h
  end

  def normalize_array(value)
    normalized_items = value.filter_map do |item|
      normalized_item = normalize_value(item)
      normalized_item unless blank_value?(normalized_item)
    end

    normalized_items.sort_by { |item| JSON.generate(item) }
  end

  def normalize_value(value)
    case value
    when Hash
      normalize_hash(value)
    when Array
      normalize_array(value)
    when String
      normalize_string(value)
    when Integer
      value
    when Float, BigDecimal
      value.to_f
    when NilClass
      nil
    end
  end

  def normalize_string(value)
    normalized = value.strip
    return if normalized.blank?

    return normalized.to_i if normalized.match?(/\A-?\d+\z/)
    return normalized.to_f if normalized.match?(/\A-?\d+\.\d+\z/)

    normalized
  end

  def blank_value?(value)
    value.respond_to?(:blank?) ? value.blank? : value.nil?
  end
end
# rubocop:enable Style/OneClassPerFile
