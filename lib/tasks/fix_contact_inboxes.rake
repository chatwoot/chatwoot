namespace :digitaltolk do
  task fix_contact_inboxes: :environment do
    arrays = [
      'anna.wilhelmsson@skola.uppsala.se',
      'info@lexly.se',
      'leyla@digitaltolk.com',
      'leyla@digitaltolk.se',
      'mikael@digitaltolk.com'
    ]

    begin
      ActiveRecord::Base.transaction do
        arrays.each do |email|
          contact = Contact.find_by(email: email)
          next if contact.blank?

          contact_inboxes = ContactInbox.where(source_id: email).where.not(contact_id: contact.id)
          contact_inboxes.each do |contact_inbox|
            next unless contact_inbox.inbox.email?

            old_contact = contact_inbox.contact

            unless ContactInbox.where(inbox_id: contact_inbox.inbox_id, source_id: old_contact.email).exists?
              contact_inbox.update_columns(source_id: old_contact.email)
            end

            new_contact_inbox = ContactInbox.find_or_create_by(
              inbox_id: contact_inbox.inbox_id,
              source_id: contact.email
            )

            if new_contact_inbox.new_record?
              new_contact_inbox.contact_id = contact.id
              new_contact_inbox.save
            end
          end
        end
      end
    rescue StandardError => e
      puts e.message
    end

    puts 'Contact inboxes fixed!'
  end
end
