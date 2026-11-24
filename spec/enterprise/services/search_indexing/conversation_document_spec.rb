require 'rails_helper'

RSpec.describe SearchIndexing::ConversationDocument do
  it 'indexes identity, subject and dates without unrelated customer metadata' do
    conversation = create(:conversation, additional_attributes: { mail_subject: 'Renewal', secret: 'excluded' })
    conversation.contact.update!(custom_attributes: { secret: 'excluded' })
    data = conversation.search_data
    expect(data).to include('account_id' => conversation.account_id, 'display_id_text' => conversation.display_id.to_s,
                            'created_at' => conversation.created_at, 'last_activity_at' => conversation.last_activity_at, 'mail_subject' => 'Renewal')
    expect(data.fetch('contact').keys).to match_array(described_class::CONTACT_FIELDS)
    expect(data.to_json).not_to include('excluded')
  end
end
