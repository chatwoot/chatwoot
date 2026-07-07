require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  describe 'message_reactions' do
    describe 'rake task' do
      subject(:task) { described_class['chatwoot:message_reactions:resubscribe_webhooks'] }

      before do
        task.reenable
      end

      it 'invokes the resubscribe job' do
        expect(Migration::ResubscribeMessageReactionWebhooksJob).to receive(:perform_now)

        task.invoke
      end
    end
  end
end
