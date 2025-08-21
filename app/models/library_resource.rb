# == Schema Information
#
# Table name: library_resources
#
#  id                :bigint           not null, primary key
#  content           :text
#  custom_attributes :jsonb
#  description       :text             not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#
# Indexes
#
#  index_library_resources_on_account_id         (account_id)
#  index_library_resources_on_custom_attributes  (custom_attributes) USING gin
#  index_library_resources_on_title              (title)
#
class LibraryResource < ApplicationRecord
  belongs_to :account

  validates :title, presence: true
  validates :description, presence: true
  validates :account, presence: true
  validates :custom_attributes, jsonb_attributes_length: true

  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event
  before_destroy :capture_destroy_data
  after_destroy_commit :dispatch_destroy_event

  def webhook_data
    {
      account: account.webhook_data,
      id: id,
      title: title,
      description: description,
      content: content,
      custom_attributes: custom_attributes,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def capture_destroy_data
    @destroy_data = {
      id: id,
      title: title,
      description: description,
      content: content,
      custom_attributes: custom_attributes,
      created_at: created_at,
      updated_at: updated_at,
      account_id: account_id,
      account: account.webhook_data
    }
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(LIBRARY_RESOURCE_CREATED, Time.zone.now, library_resource: self)
  end

  def dispatch_update_event
    return if previous_changes.blank?

    Rails.configuration.dispatcher.dispatch(LIBRARY_RESOURCE_UPDATED, Time.zone.now, library_resource: self, changed_attributes: previous_changes)
  end

  def dispatch_destroy_event
    Rails.configuration.dispatcher.dispatch(LIBRARY_RESOURCE_DELETED, Time.zone.now, library_resource: @destroy_data)
  end
end
