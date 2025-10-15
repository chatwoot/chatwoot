module InstagramSpecHelpers
  def create_instagram_contact_for_sender(sender_id, inbox)
    contact = Contact.find_by(identifier: sender_id)
    if contact.nil?
      contact = create(:contact, identifier: sender_id, name: 'Jane Dae')
      create(:contact_inbox, contact_id: contact.id, inbox_id: inbox.id, source_id: sender_id)
    end
    contact
  end

  def instagram_user_response_object_for(sender_id, account_id)
    {
      name: 'Jane',
      id: sender_id,
      account_id: account_id,
      profile_pic: 'https://chatwoot-assets.local/sample.png',
      username: 'some_user_name'
    }
  end
end
