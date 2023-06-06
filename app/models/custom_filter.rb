# == Schema Information
#
# Table name: custom_filters
#
#  id          :bigint           not null, primary key
#  filter_type :integer          default("conversation"), not null
#  name        :string           not null
#  query       :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_custom_filters_on_account_id  (account_id)
#  index_custom_filters_on_user_id     (user_id)
#
class CustomFilter < ApplicationRecord
  MAX_FILTER_PER_USER = 50
  belongs_to :user
  belongs_to :account

  enum filter_type: { conversation: 0, contact: 1, report: 2 }
  validate :validate_number_of_filters

  def records_count
    fetch_record_count_from_redis
  end

  def filter_records
    Conversations::FilterService.new(query.with_indifferent_access, user, account).perform
  end

  def set_record_count_in_redis
    records = filter_records
    Redis::Alfred.set(filter_count_key, records[:count][:all_count])
  end

  def fetch_record_count_from_redis
    number_of_records = Redis::Alfred.get(filter_count_key)
    SyncCustomFilterCountJob.perform_later(self) if number_of_records.nil?
    number_of_records
  end

  def filter_count_key
    format(::Redis::Alfred::CUSTOM_FILTER_RECORDS_COUNT_KEY, account_id: account_id, filter_id: id, user_id: user_id)
  end

  def validate_number_of_filters
    return true if account.custom_filters.where(user_id: user_id).size < MAX_FILTER_PER_USER

    errors.add :account_id, I18n.t('errors.custom_filters.number_of_records')
  end
end
