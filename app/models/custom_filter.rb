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
  belongs_to :user
  belongs_to :account

  enum filter_type: { conversation: 0, contact: 1, report: 2 }
  validate :validate_number_of_filters
  after_create_commit :invalidate_filtered_unread_count_create
  after_update_commit :invalidate_filtered_unread_count_update
  after_destroy_commit :invalidate_filtered_unread_count_destroy

  def validate_number_of_filters
    return true if account.custom_filters.where(user_id: user_id).size < Limits::MAX_CUSTOM_FILTERS_PER_USER

    errors.add :account_id, I18n.t('errors.custom_filters.number_of_records')
  end

  private

  def invalidate_filtered_unread_count_create
    filtered_count_invalidator.custom_filter_created!(self)
  end

  def invalidate_filtered_unread_count_update
    filtered_count_invalidator.custom_filter_updated!(self)
  end

  def invalidate_filtered_unread_count_destroy
    filtered_count_invalidator.custom_filter_destroyed!(self)
  end

  def filtered_count_invalidator
    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account)
  end
end
