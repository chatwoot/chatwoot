module MetaCampaigns
  class InteractionTrackerService
    pattr_initialize [:message!]

    def perform
      return unless should_track?

      create_interaction
    end

    private

    def should_track?
      return false unless message.incoming?
      return false unless whatsapp_message?
      return false unless has_referral_data?

      true
    end

    def whatsapp_message?
      message.inbox.channel_type == 'Channel::Whatsapp'
    end

    def has_referral_data?
      referral_data.present? && referral_data['source_id'].present?
    end

    def referral_data
      @referral_data ||= message.additional_attributes&.dig('referral') ||
                         message.conversation.additional_attributes&.dig('meta_ad_campaign')
    end

    def create_interaction
      MetaCampaignInteraction.create!(
        inbox: message.inbox,
        account: message.account,
        conversation: message.conversation,
        message: message,
        source_id: referral_data['source_id'],
        source_type: referral_data['source_type'],
        ctwa_clid: referral_data['ctwa_clid'],
        interaction_type: 'initial_message',
        metadata: {
          headline: referral_data['headline'],
          body: referral_data['body'],
          media_type: referral_data['media_type'],
          image_url: referral_data['image_url'],
          video_url: referral_data['video_url'],
          source_url: referral_data['source_url']
        }.compact
      )
    rescue ActiveRecord::RecordNotUnique
      # Interaction already exists, skip
      Rails.logger.info "Meta campaign interaction already exists for message #{message.id}"
    end
  end
end
