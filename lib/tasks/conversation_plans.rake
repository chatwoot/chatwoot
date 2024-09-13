namespace :conversation_plans do
  desc 'Migrate data to the conversation plans'
  task migrate_data_to_conversation_plans: :environment do
    ActiveRecord::Base.transaction do
      Conversation.where('conversation_type = 1').each do |conversation|
        description = conversation.additional_attributes.dig("description")
        created_by_id = conversation.additional_attributes.dig("created_by")
        next unless description && created_by_id
        created_by = User.find_by_id(created_by_id)
        account = conversation.account
        contact = conversation.contact
        conversation_plan = conversation.conversation_plans.create!(
          description: description,
          created_by: created_by,
          account: account,
          contact: contact,
          completed_at: (conversation.updated_at if conversation.resolved?),
          )
        puts conversation_plan
      end
    end
  rescue StandardError => e
    puts e.message
  end
end
