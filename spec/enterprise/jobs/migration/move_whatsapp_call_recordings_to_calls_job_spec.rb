require 'rails_helper'

RSpec.describe Migration::MoveWhatsappCallRecordingsToCallsJob, type: :job do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:message) { create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox, content_type: 'voice_call') }

  def attach_audio(meta = {})
    message.attachments.create!(account: conversation.account, file_type: :audio, meta: meta,
                                file: fixture_file_upload(Rails.root.join('spec/assets/sample.ogg'), 'audio/ogg'))
  end

  it 'moves the recording and its transcript from the message onto the WhatsApp call without copying the file' do
    call = create(:call, conversation: conversation, provider: :whatsapp, message: message)
    attachment = attach_audio('transcribed_text' => 'hello from whatsapp')
    blob = attachment.file.blob

    described_class.perform_now

    call.reload
    expect(call.recording.blob).to eq(blob)
    expect(call.transcript).to eq('hello from whatsapp')
    expect(message.attachments.reload).to be_empty
    expect(ActiveStorage::Blob.exists?(blob.id)).to be(true)
  end

  it 'moves a recording that was never transcribed' do
    call = create(:call, conversation: conversation, provider: :whatsapp, message: message)
    attach_audio

    described_class.perform_now

    expect(call.reload.recording).to be_attached
    expect(call.transcript).to be_nil
  end

  it 'leaves Twilio calls alone' do
    create(:call, conversation: conversation, provider: :twilio, message: message)
    attach_audio

    expect { described_class.perform_now }.not_to(change { message.attachments.count })
  end
end
