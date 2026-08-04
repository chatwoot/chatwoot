require 'rails_helper'

RSpec.describe Captain::Tools::SearchReplyDocumentationService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:service) { described_class.new(account: account, assistant: assistant) }
  let(:translator) { instance_double(Captain::Llm::TranslateQueryService, translate: 'reset password') }

  before do
    allow(Captain::Llm::TranslateQueryService).to receive(:new).with(account: account).and_return(translator)
  end

  it 'identifies reply suggestion searches and includes the assistant' do
    expect(Captain::AssistantResponse).to receive(:search).with(
      'reset password',
      account_id: account.id,
      embedding_source: 'reply_suggestion',
      embedding_metadata: { assistant_id: assistant.id }
    ).and_return([])

    expect(service.execute(query: 'password help')).to eq('No FAQs found for the given query')
  end
end
