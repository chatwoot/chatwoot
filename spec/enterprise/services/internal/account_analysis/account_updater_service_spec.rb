require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::AccountUpdaterService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account) }
  let(:discord_notifier) { instance_double(Internal::AccountAnalysis::DiscordNotifierService, notify_flagged_account: true) }

  before do
    allow(Internal::AccountAnalysis::DiscordNotifierService).to receive(:new).and_return(discord_notifier)
    allow(Rails.logger).to receive(:info)
  end

  describe '#update_with_analysis' do
    context 'when error_message is provided' do
      it 'saves the error and notifies Discord' do
        service.update_with_analysis({}, 'Analysis failed')

        expect(account.internal_attributes['security_flagged']).to be true
        expect(account.internal_attributes['security_flag_reason']).to eq('Error: Analysis failed')
        expect(discord_notifier).to have_received(:notify_flagged_account).with(account)
      end
    end

    context 'when analysis is successful' do
      let(:analysis) do
        {
          'threat_level' => 'none',
          'threat_summary' => 'No threats detected',
          'recommendation' => 'allow'
        }
      end

      it 'saves the analysis results' do
        allow(Time).to receive(:current).and_return('2023-01-01 12:00:00')

        service.update_with_analysis(analysis)

        expect(account.internal_attributes['last_threat_scan_at']).to eq('2023-01-01 12:00:00')
        expect(account.internal_attributes['last_threat_scan_level']).to eq('none')
        expect(account.internal_attributes['last_threat_scan_summary']).to eq('No threats detected')
        expect(account.internal_attributes['last_threat_scan_recommendation']).to eq('allow')
      end

      it 'does not flag the account when threat level is none' do
        service.update_with_analysis(analysis)

        expect(account.internal_attributes).not_to include('security_flagged')
        expect(discord_notifier).not_to have_received(:notify_flagged_account)
      end
    end

    context 'when analysis detects high threat level' do
      let(:analysis) do
        {
          'threat_level' => 'high',
          'threat_summary' => 'Suspicious activity detected',
          'recommendation' => 'review',
          'illegal_activities_detected' => false
        }
      end

      it 'flags the account and notifies Discord' do
        service.update_with_analysis(analysis)

        expect(account.internal_attributes['security_flagged']).to be true
        expect(account.internal_attributes['security_flag_reason']).to eq('Threat detected: Suspicious activity detected')
        expect(discord_notifier).to have_received(:notify_flagged_account).with(account)
        expect(Rails.logger).to have_received(:info).with("Flagging account #{account.id} due to threat level: high")
        expect(Rails.logger).to have_received(:info).with("Account #{account.id} has been flagged for security review")
      end
    end

    context 'when analysis detects medium threat level' do
      let(:analysis) do
        {
          'threat_level' => 'medium',
          'threat_summary' => 'Potential issues found',
          'recommendation' => 'review',
          'illegal_activities_detected' => false
        }
      end

      it 'flags the account and notifies Discord' do
        service.update_with_analysis(analysis)

        expect(account.internal_attributes['security_flagged']).to be true
        expect(account.internal_attributes['security_flag_reason']).to eq('Threat detected: Potential issues found')
        expect(discord_notifier).to have_received(:notify_flagged_account).with(account)
      end
    end

    context 'when analysis detects illegal activities' do
      let(:analysis) do
        {
          'threat_level' => 'low',
          'threat_summary' => 'Minor issues found',
          'recommendation' => 'review',
          'illegal_activities_detected' => true
        }
      end

      it 'flags the account and notifies Discord' do
        service.update_with_analysis(analysis)

        expect(account.internal_attributes['security_flagged']).to be true
        expect(account.internal_attributes['security_flag_reason']).to eq('Threat detected: Minor issues found')
        expect(discord_notifier).to have_received(:notify_flagged_account).with(account)
      end
    end

    context 'when analysis recommends blocking' do
      let(:analysis) do
        {
          'threat_level' => 'low',
          'threat_summary' => 'Minor issues found',
          'recommendation' => 'block',
          'illegal_activities_detected' => false
        }
      end

      it 'flags the account and notifies Discord' do
        service.update_with_analysis(analysis)

        expect(account.internal_attributes['security_flagged']).to be true
        expect(account.internal_attributes['security_flag_reason']).to eq('Threat detected: Minor issues found')
        expect(discord_notifier).to have_received(:notify_flagged_account).with(account)
      end
    end
  end
end
