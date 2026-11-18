# == Schema Information
#
# Table name: custom_filters
#
#  id          :bigint           not null, primary key
#  filter_type :integer          default("conversation"), not null
#  name        :string           not null
#  query       :jsonb            not null
#  visibility  :integer          default("personal"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_custom_filters_on_account_id                    (account_id)
#  index_custom_filters_on_account_type_visibility_user  (account_id,filter_type,visibility,user_id)
#  index_custom_filters_on_user_id                       (user_id)
#
class CustomFilter < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum :filter_type, { conversation: 0, contact: 1, report: 2 }
  # Declared so older migrations that load this model still run before the visibility column exists.
  attribute :visibility, :integer, default: 0
  enum :visibility, { personal: 0, global: 1 }, validate: true

  validate :validate_number_of_filters
  after_create_commit :invalidate_filtered_unread_count_create
  after_update_commit :invalidate_filtered_unread_count_update
  after_destroy_commit :invalidate_filtered_unread_count_destroy

  def set_visibility(user, params)
    self.visibility = params[:visibility] if params.key?(:visibility)
    self.visibility = :personal if user.agent?
  end

  def self.with_visibility(user, params)
    filter_type = params[:filter_type].to_s
    filter_type = 'conversation' unless filter_types.key?(filter_type)
    scope = Current.account.custom_filters.where(filter_type: filter_type)
    scope.global.or(scope.personal.where(user_id: user.id)).order(:id)
  end

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
