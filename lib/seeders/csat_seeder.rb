## Class to generate sample CSAT survey responses for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with CSAT responses
#   Seeders::CsatSeeder.new(account: Account.find(1)).perform!
#
#
############################################################

class Seeders::CsatSeeder
  def initialize(account:)
    raise 'CSAT Seeding is not allowed in production.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
  end

  def perform!
    seed_csat_responses
  end

  private

  def seed_csat_responses
    resolved_conversations = @account.conversations.where(status: :resolved)
    csat_enabled_inboxes = @account.inboxes.where(csat_survey_enabled: true)

    return if resolved_conversations.empty? || csat_enabled_inboxes.empty?

    # Create CSAT responses for resolved conversations in CSAT-enabled inboxes
    resolved_conversations.joins(:inbox).where(inbox: csat_enabled_inboxes).find_each do |conversation|
      # Only create CSAT for about 70% of resolved conversations to simulate real-world scenarios
      next if rand > 0.7

      # Get the last outgoing message to attach CSAT to
      last_outgoing_message = conversation.messages.where(message_type: :outgoing).last
      next unless last_outgoing_message

      # Create CSAT survey response with varied ratings and feedback
      create_csat_response(conversation, last_outgoing_message)
    end
  end

  def create_csat_response(conversation, message)
    # Generate realistic rating distribution (more positive ratings)
    rating = case rand
             when 0.0..0.05 then 1  # 5%
             when 0.05..0.15 then 2 # 10%
             when 0.15..0.35 then 3 # 20%
             when 0.35..0.65 then 4 # 30%
             else 5                 # 35%
             end

    feedback_messages = [
      'Great service, very helpful!',
      'Quick response and resolved my issue',
      'Professional and courteous support',
      'Could be faster but overall good',
      'Satisfied with the resolution',
      'Excellent customer service',
      'Very knowledgeable agent',
      'Resolved quickly, thank you!',
      'Good experience overall',
      'Agent was very patient and helpful',
      'Really appreciate the help',
      'Fast and efficient service',
      'Agent went above and beyond',
      'Clear explanations provided',
      'Issue resolved on first contact',
      '',  # Some responses have no feedback
      '',
      ''
    ]

    CsatSurveyResponse.create!(
      account: @account,
      conversation: conversation,
      contact: conversation.contact,
      message: message,
      assigned_agent: conversation.assignee,
      rating: rating,
      feedback_message: feedback_messages.sample,
      created_at: message.created_at + rand(5..30).minutes
    )
  rescue StandardError => e
    Rails.logger.debug { "Failed to create CSAT response: #{e.message}" }
  end
end