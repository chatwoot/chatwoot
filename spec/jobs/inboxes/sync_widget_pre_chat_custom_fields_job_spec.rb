require 'rails_helper'

RSpec.describe Inboxes::SyncWidgetPreChatCustomFieldsJob do
  pre_chat_fields = [{
    'label' => 'Developer Id',
    'name' => 'developer_id'
  }, {
    'label' => 'Full Name',
    'name' => 'full_name'
  }]
  pre_chat_message = 'Share your queries here.'
  let!(:account) { create(:account) }
  let!(:web_widget) do
    create(:channel_widget, account: account, pre_chat_form_options: { pre_chat_message: pre_chat_message, pre_chat_fields: pre_chat_fields })
  end

  context 'when called' do
    it 'sync pre chat fields if custom attribute deleted' do
      described_class.perform_now(account, 'developer_id')
      expect(web_widget.reload.pre_chat_form_options['pre_chat_fields']).to eq [{
        'label' => 'Full Name',
        'name' => 'full_name'
      }]
    end
  end
end
