namespace :contacts do
  desc 'Populate is_verified column for existing contacts based on verification criteria'
  task populate_verification: :environment do
    total_contacts = Contact.count
    puts "Total contacts to process: #{total_contacts}"

    batch_size = 1000
    updated_count = 0

    Contact.find_each(batch_size: batch_size) do |contact|
      # Check if contact should be verified using the same logic as model
      should_be_verified = contact.email.present? ||
                           contact.phone_number.present? ||
                           contact.identifier.present? ||
                           (contact.additional_attributes.present? && contact.additional_attributes['company_name'].present?)

      # Update only if current value is different (avoid unnecessary updates)
      if contact.is_verified != should_be_verified
        # Using update_columns to avoid callbacks and validations for bulk operation
        contact.update_columns(is_verified: should_be_verified) # rubocop:disable Rails/SkipsModelValidations
        updated_count += 1
      end
      # Progress indicator
      puts "Updated #{updated_count} contacts..." if (updated_count % 100).zero?
    end
  end
end
