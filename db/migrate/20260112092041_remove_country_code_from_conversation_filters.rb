class RemoveCountryCodeFromConversationFilters < ActiveRecord::Migration[7.1]
  def up
    CustomFilter.conversation
                .where('query::text LIKE ?', '%country_code%')
                .find_each do |custom_filter|
      query = custom_filter.query || {}
      payload = query['payload']

      next unless payload.is_a?(Array)

      updated_payload = payload.reject do |filter|
        filter.is_a?(Hash) && filter['attribute_key'] == 'country_code'
      end

      next if updated_payload == payload

      if updated_payload.empty?
        custom_filter.delete
        next
      end

      # rubocop:disable Rails/SkipsModelValidations
      # we will skip model validation, since we don't want any callbacks running
      custom_filter.update_columns(query: query.merge('payload' => updated_payload))
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    # no-op: removed filters cannot be restored reliably
  end
end
