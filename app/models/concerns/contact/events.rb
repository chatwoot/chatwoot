module Contact::Events
  extend ActiveSupport::Concern

  included do
    after_create_commit :dispatch_create_event, :ip_lookup
    after_update_commit :dispatch_update_event
    after_destroy_commit :dispatch_destroy_event
  end

  private

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(CONTACT_CREATED, Time.zone.now, contact: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(
      CONTACT_UPDATED,
      Time.zone.now,
      contact: self,
      changed_attributes: previous_changes
    )
  end

  def dispatch_destroy_event
    Rails.configuration.dispatcher.dispatch(CONTACT_DELETED, Time.zone.now, contact: self)
  end

  def ip_lookup
    return unless account.feature_enabled?('ip_lookup')

    ContactIpLookupJob.perform_later(self)
  end
end
