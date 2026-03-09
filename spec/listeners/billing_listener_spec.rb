require 'rails_helper'

describe BillingListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }

  describe '#account_created' do
    let(:event) { Events::Base.new('account.created', Time.zone.now, account: account) }

    it 'grants a 14-day Pro trial with 500 credits' do
      listener.account_created(event)

      account.reload
      expect(account.on_trial?).to be true
      expect(account.trial_credits_remaining).to eq(500)
      expect(account.active_plan.key).to eq('pro_monthly')
    end

    it 'sets trial_ends_at to approximately 14 days from now' do
      freeze_time do
        listener.account_created(event)

        sub = account.reload.active_subscription
        expect(sub.trial_ends_at).to be_within(1.second).of(14.days.from_now)
      end
    end

    it 'syncs pro plan features' do
      listener.account_created(event)

      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
      expect(account.limits['knowledge_base_documents']).to eq(200)
    end

    it 'ignores events without an Account' do
      bad_event = Events::Base.new('account.created', Time.zone.now, account: 'not_an_account')
      expect { listener.account_created(bad_event) }.not_to raise_error
    end
  end
end
