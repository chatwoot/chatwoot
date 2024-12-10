namespace :custom_attributes do
  desc 'Add calling status and notes custom attributes to all accounts'
  task add_calling_attributes: :environment do
    calling_status_values = ['Scheduled', 'Not Picked', 'Follow-up', 'Converted', 'Dropped']

    Account.find_each do |account|
      # Create Calling Status attribute (list type)
      CustomAttributeDefinition.find_or_create_by!(
        account: account,
        attribute_key: 'calling_status',
        attribute_model: :conversation_attribute
      ) do |cad|
        cad.attribute_display_name = 'Calling Status'
        cad.attribute_display_type = :list
        cad.attribute_values = calling_status_values
        cad.attribute_description = 'Track the status of calls for conversations'
      end

      # Create Calling Notes attribute (text type)
      CustomAttributeDefinition.find_or_create_by!(
        account: account,
        attribute_key: 'calling_notes',
        attribute_model: :conversation_attribute
      ) do |cad|
        cad.attribute_display_name = 'Calling Notes'
        cad.attribute_display_type = :text
        cad.attribute_description = 'Notes related to calls for this conversation'
      end

      puts "Created calling attributes for Account ##{account.id}"
    end

    puts 'Completed adding calling attributes to all accounts'
  end
end
