# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  include ActiveJob::TestHelper

  describe 'associations' do
    it { is_expected.to have_many(:sla_policies).dependent(:destroy_async) }
    it { is_expected.to have_many(:applied_slas).dependent(:destroy_async) }
    it { is_expected.to have_many(:custom_roles).dependent(:destroy_async) }
  end

  describe 'sla_policies' do
    let!(:account) { create(:account) }
    let!(:sla_policy) { create(:sla_policy, account: account) }

    it 'returns associated sla policies' do
      expect(account.sla_policies).to eq([sla_policy])
    end

    it 'deletes associated sla policies' do
      perform_enqueued_jobs do
        account.destroy!
      end
      expect { sla_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'usage_limits' do
    let(:captain_limits) do
      {
        :startups => { :documents => 100, :responses => 100 },
        :business => { :documents => 200, :responses => 300 },
        :enterprise => { :documents => 300, :responses => 500 }
      }.with_indifferent_access
    end
    let!(:account) { create(:account, { custom_attributes: { plan_name: 'startups' } }) }
    let!(:assistant) { create(:captain_assistant, account: account) }
    let!(:document) { create(:captain_document, assistant: assistant, account: account, status: :available) }

    before do
      create(:installation_config, name: 'ACCOUNT_AGENTS_LIMIT', value: 20)
      create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS', value: captain_limits.to_json)
    end

    describe 'captain limits' do
      it 'returns monthly limit accurately' do
        %w[startups business enterprise].each do |plan|
          account.custom_attributes = { 'plan_name': plan }
          account.save!
          expect(account.captain_monthly_limit).to eq captain_limits[plan]
        end
      end

      it 'incrementing responses updates usage_limits' do
        account.increment_response_usage

        responses_limits = account.usage_limits[:captain][:generated_responses]

        expect(account.limits['captain_responses']).to eq 1
        expect(responses_limits[:consumed]).to eq 1
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses] - 1
      end

      it 'reseting responses limits updates usage_limits' do
        account.limits['captain_responses'] = 30
        account.save!

        responses_limits = account.usage_limits[:captain][:generated_responses]

        expect(responses_limits[:consumed]).to eq 30
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses] - 30

        account.reset_response_usage
        responses_limits = account.usage_limits[:captain][:generated_responses]

        expect(account.limits['captain_responses']).to eq 0
        expect(responses_limits[:consumed]).to eq 0
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses]
      end

      it 'reflects document limits' do
        document_limits = account.usage_limits[:captain][:documents]

        expect(document_limits[:consumed]).to eq 1
        expect(document_limits[:current_available]).to eq captain_limits[:startups][:documents] - 1
      end

      it 'current_available is never out of bounds' do
        account.limits['captain_responses'] = 3000
        account.save!

        responses_limits = account.usage_limits[:captain][:generated_responses]
        expect(responses_limits[:consumed]).to eq 3000
        expect(responses_limits[:current_available]).to eq 0

        account.limits['captain_responses'] = -100
        account.save!

        responses_limits = account.usage_limits[:captain][:generated_responses]
        expect(responses_limits[:consumed]).to eq 0
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses]
      end
    end

    describe 'audit logs' do
      it 'returns audit logs' do
        # checking whether associated_audits method is present
        expect(account.associated_audits.present?).to be false
      end

      it 'creates audit logs when account is updated' do
        account.update(name: 'New Name')
        expect(Audited::Audit.where(auditable_type: 'Account', action: 'update').count).to eq 1
      end
    end

    it 'returns max limits from global config when enterprise version' do
      expect(account.usage_limits).to eq(
        {
          agents: 20,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from account when enterprise version' do
      account.update(limits: { agents: 10 })
      expect(account.usage_limits).to eq(
        {
          agents: 10,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns limits based on subscription' do
      account.update(limits: { agents: 10 }, custom_attributes: { subscribed_quantity: 5 })
      expect(account.usage_limits).to eq(
        {
          agents: 5,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from global config if account limit is absent' do
      account.update(limits: { agents: '' })
      expect(account.usage_limits).to eq(
        {
          agents: 20,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from app limit if account limit and installation config is absent' do
      account.update(limits: { agents: '' })
      InstallationConfig.where(name: 'ACCOUNT_AGENTS_LIMIT').update(value: '')

      expect(account.usage_limits).to eq(
        {
          agents: ChatwootApp.max_limit,
          inboxes: ChatwootApp.max_limit
        }
      )
    end
  end

  describe 'subscribed_features' do
    let(:account) { create(:account) }
    let(:plan_features) do
      {
        'hacker' => %w[feature1 feature2],
        'startups' => %w[feature1 feature2 feature3 feature4]
      }
    end

    before do
      InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLAN_FEATURES').first_or_create(value: plan_features)
    end

    context 'when plan_name is hacker' do
      it 'returns the features for the hacker plan' do
        account.custom_attributes = { 'plan_name': 'hacker' }
        account.save!

        expect(account.subscribed_features).to eq(%w[feature1 feature2])
      end
    end

    context 'when plan_name is startups' do
      it 'returns the features for the startups plan' do
        account.custom_attributes = { 'plan_name': 'startups' }
        account.save!

        expect(account.subscribed_features).to eq(%w[feature1 feature2 feature3 feature4])
      end
    end

    context 'when plan_features is blank' do
      it 'returns an empty array' do
        account.custom_attributes = {}
        account.save!

        expect(account.subscribed_features).to be_nil
      end
    end
  end
end
