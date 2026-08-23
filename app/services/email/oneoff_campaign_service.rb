# frozen_string_literal: true

# Kiraid cold-outreach email campaign.
#
# For an Email inbox, a "campaign message" is just the opening email of a new
# conversation. We create a contact_inbox (linking the contact to the inbox),
# then a conversation + first outgoing message via the shared
# Campaigns::CampaignConversationBuilder. That builder enqueues the message,
# which SendReplyJob delivers through Email::SendOnEmailService -> SMTP.
#
# This keeps email campaigns on the exact same send path as a human agent
# composing an email, so From/Reply-To/Signatures all work unchanged.
#
# REMOVE THIS FEATURE by deleting this service and the `when 'Email'` branch in
# app/models/campaign.rb#execute_campaign (plus reverting the inbox allow-list).
module Email
  class OneoffCampaignService
    pattr_initialize [:campaign!]

    def perform
      validate_campaign!
      process_audience
      campaign.completed!
    end

    private

    delegate :inbox, to: :campaign
    delegate :channel, to: :inbox

    def validate_campaign!
      raise "Invalid campaign #{campaign.id}" unless campaign.one_off?
      raise 'Completed Campaign' if campaign.completed?
      raise 'Inbox is not an Email inbox' unless inbox.email?
    end

    def process_audience
      contacts = audience_contacts
      Rails.logger.info "Email campaign #{campaign.id}: processing #{contacts.count} contacts"

      contacts.find_each do |contact|
        begin
          process_contact(contact)
        rescue StandardError => e
          Rails.logger.error "Email campaign #{campaign.id}: failed for contact #{contact.id} - #{e.message}"
        end
      end
    end

    # Audience resolution: labels (like other campaign channels) if an audience
    # was supplied, otherwise every contact that has an email on the account.
    def audience_contacts
      label_titles = campaign.audience
                        .select { |a| a['type'] == 'Label' }
                        .pluck('id')
                        .then { |ids| campaign.account.labels.where(id: ids).pluck(:title) }

      scope = campaign.account.contacts.where.not(email: [nil, ''])
      scope = scope.tagged_with(label_titles, any: true) if label_titles.any?
      scope
    end

    def process_contact(contact)
      return if contact.email.blank?

      contact_inbox = find_or_create_contact_inbox(contact)
      Campaigns::CampaignConversationBuilder.new(
        contact_inbox_id: contact_inbox.id,
        campaign_display_id: campaign.display_id,
        conversation_additional_attributes: { mail_subject: campaign.trigger_rules&.dig('mail_subject') }.compact
      ).perform
    end

    def find_or_create_contact_inbox(contact)
      ContactInboxBuilder.new(contact: contact, inbox: inbox).perform
    end
  end
end
