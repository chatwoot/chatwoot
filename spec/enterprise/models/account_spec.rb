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

  context 'with usage_limits' do
    let(:captain_limits) do
      {
        :startups => { :documents => 100, :responses => 100 },
        :business => { :documents => 200, :responses => 300 },
        :enterprise => { :documents => 300, :responses => 500 }
      }.with_indifferent_access
    end
    let(:account) { create(:account, { custom_attributes: { plan_name: 'startups' } }) }
    let(:assistant) { create(:captain_assistant, account: account) }

    before do
      create(:installation_config, name: 'ACCOUNT_AGENTS_LIMIT', value: 20)
    end

    describe 'when captain limits are configured' do
      before do
        create_list(:captain_document, 3, account: account, assistant: assistant, status: :available)
        create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS', value: captain_limits.to_json)
      end

      ## Document
      it 'updates document count accurately' do
        account.update_document_usage
        expect(account.custom_attributes['captain_documents_usage']).to eq(3)
      end

      it 'handles zero documents' do
        account.captain_documents.destroy_all
        account.update_document_usage
        expect(account.custom_attributes['captain_documents_usage']).to eq(0)
      end

      it 'reflects document limits' do
        document_limits = account.usage_limits[:captain][:documents]

        expect(document_limits[:consumed]).to eq 3
        expect(document_limits[:current_available]).to eq captain_limits[:startups][:documents] - 3
      end

      ## Responses
      it 'incrementing responses updates usage_limits' do
        account.increment_response_usage

        responses_limits = account.usage_limits[:captain][:responses]

        expect(account.custom_attributes['captain_responses_usage']).to eq 1
        expect(responses_limits[:consumed]).to eq 1
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses] - 1
      end

      it 'reseting responses limits updates usage_limits' do
        account.custom_attributes['captain_responses_usage'] = 30
        account.save!

        responses_limits = account.usage_limits[:captain][:responses]

        expect(responses_limits[:consumed]).to eq 30
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses] - 30

        account.reset_response_usage
        responses_limits = account.usage_limits[:captain][:responses]

        expect(account.custom_attributes['captain_responses_usage']).to eq 0
        expect(responses_limits[:consumed]).to eq 0
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses]
      end

      it 'returns monthly limit accurately' do
        %w[startups business enterprise].each do |plan|
          account.custom_attributes = { 'plan_name': plan }
          account.save!
          expect(account.captain_monthly_limit).to eq captain_limits[plan]
        end
      end

      it 'current_available is never out of bounds' do
        account.custom_attributes['captain_responses_usage'] = 3000
        account.save!

        responses_limits = account.usage_limits[:captain][:responses]
        expect(responses_limits[:consumed]).to eq 3000
        expect(responses_limits[:current_available]).to eq 0

        account.custom_attributes['captain_responses_usage'] = -100
        account.save!

        responses_limits = account.usage_limits[:captain][:responses]
        expect(responses_limits[:consumed]).to eq 0
        expect(responses_limits[:current_available]).to eq captain_limits[:startups][:responses]
      end
    end

    describe 'when captain limits are not configured' do
      it 'returns default values' do
        account.custom_attributes = { 'plan_name': 'unknown' }
        expect(account.captain_monthly_limit).to eq(
          { documents: ChatwootApp.max_limit, responses: ChatwootApp.max_limit }.with_indifferent_access
        )
      end
    end

    describe 'when limits are configured for an account' do
      before do
        create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS', value: captain_limits.to_json)
        account.update!(limits: { captain_documents: 5555, captain_responses: 9999 })
      end

      it 'returns limits based on custom attributes' do
        usage_limits = account.usage_limits
        expect(usage_limits[:captain][:documents][:total_count]).to eq(5555)
        expect(usage_limits[:captain][:responses][:total_count]).to eq(9999)
      end
    end

    describe 'audit logs' do
      it 'returns audit logs' do
        # checking whether associated_audits method is present
        expect(account.associated_audits.present?).to be false
      end

      it 'creates audit logs when account is updated' do
        account.update!(name: 'New Name')
        expect(Audited::Audit.where(auditable_type: 'Account', action: 'update').count).to eq 1
      end
    end

    it 'returns max limits from global config when enterprise version' do
      expect(account.usage_limits[:agents]).to eq(20)
    end

    it 'returns max limits from account when enterprise version' do
      account.update!(limits: { agents: 10 })
      expect(account.usage_limits[:agents]).to eq(10)
    end

    it 'returns limits based on subscription' do
      account.update!(limits: { agents: 10 }, custom_attributes: { subscribed_quantity: 5 })
      expect(account.usage_limits[:agents]).to eq(5)
    end

    it 'returns max limits from global config if account limit is absent' do
      account.update!(limits: { agents: '' })
      expect(account.usage_limits[:agents]).to eq(20)
    end

    it 'returns max limits from app limit if account limit and installation config is absent' do
      account.update!(limits: { agents: '' })
      InstallationConfig.where(name: 'ACCOUNT_AGENTS_LIMIT').update!(value: '')

      expect(account.usage_limits[:agents]).to eq(ChatwootApp.max_limit)
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

  describe 'account deletion' do
    let(:account) { create(:account) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    describe '#mark_for_deletion' do
      it 'sets the marked_for_deletion_at and marked_for_deletion_reason attributes' do
        expect do
          account.mark_for_deletion('test_reason')
        end.to change { account.reload.custom_attributes['marked_for_deletion_at'] }.from(nil).to(be_present)
           .and change { account.reload.custom_attributes['marked_for_deletion_reason'] }.from(nil).to('test_reason')
      end

      it 'sends a notification email to admin users' do
        mailer = double
        expect(AdministratorNotifications::AccountNotificationMailer).to receive(:with).with(account: account).and_return(mailer)
        expect(mailer).to receive(:account_deletion).with(account, 'test_reason').and_return(mailer)
        expect(mailer).to receive(:deliver_later)

        account.mark_for_deletion('test_reason')
      end

      it 'returns true when successful' do
        expect(account.mark_for_deletion).to be_truthy
      end
    end

    describe '#unmark_for_deletion' do
      before do
        account.update!(
          custom_attributes: {
            'marked_for_deletion_at' => 7.days.from_now.iso8601,
            'marked_for_deletion_reason' => 'test_reason'
          }
        )
      end

      it 'removes the marked_for_deletion_at and marked_for_deletion_reason attributes' do
        expect do
          account.unmark_for_deletion
        end.to change { account.reload.custom_attributes['marked_for_deletion_at'] }.from(be_present).to(nil)
           .and change { account.reload.custom_attributes['marked_for_deletion_reason'] }.from('test_reason').to(nil)
      end

      it 'returns true when successful' do
        expect(account.unmark_for_deletion).to be_truthy
      end
    end
  end
end
