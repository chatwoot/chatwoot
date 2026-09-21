require 'rails_helper'

RSpec.describe Copilot::V2::EvidenceSerializer do
  it 'preserves body, email, attachment and call text as separately identified evidence without extraction' do
    message = create(:message, content: 'Body', content_attributes: { email: { text_content: { quoted: 'Email text' } } })
    attachment = message.attachments.create!(account_id: message.account_id, file_type: :audio, meta: { transcribed_text: 'Audio words' })
    unexamined = message.attachments.create!(account_id: message.account_id, file_type: :file)
    call = create(:call, conversation: message.conversation, message: message, transcript: 'Call words')
    evidence = described_class.message(message.reload)
    expect(evidence['parts'].pluck('text')).to contain_exactly('Body', 'Email text', 'Audio words', 'Call words')
    expect(evidence['parts'].pluck('id')).to contain_exactly("message:#{message.id}:body", "message:#{message.id}:email",
                                                             "attachment:#{attachment.id}:transcript", "call:#{call.id}:transcript")
    expect(evidence['limitations']).to include('processed_email_may_be_truncated',
                                               { 'reason' => 'unexamined_attachment', 'attachment_id' => unexamined.id, 'file_type' => 'file' })
  end
end
