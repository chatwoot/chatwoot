require 'rails_helper'

describe V2::Reports::Concerns::RollupConditions do
  let(:dummy_class) do
    Class.new do
      include V2::Reports::Concerns::RollupConditions

      attr_accessor :account, :params

      # Make private methods public for testing
      public :metric_to_rollup_metric, :dimension_type_to_rollup
    end
  end

  let(:account) { create(:account, reporting_timezone: 'America/New_York') }
  let(:builder) { dummy_class.new }

  before do
    builder.account = account
    allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(true)
  end

  describe '#use_rollup?' do
    let(:valid_params) do
      {
        metric: 'avg_resolution_time',
        type: 'account',
        group_by: 'day',
        timezone_offset: -5
      }
    end

    context 'when all conditions pass' do
      it 'returns true' do
        builder.params = valid_params
        expect(builder.use_rollup?).to be true
      end
    end

    context 'Condition 0: reporting_timezone is blank' do
      it 'returns false' do
        account.update!(reporting_timezone: nil)
        builder.params = valid_params
        expect(builder.use_rollup?).to be false
      end
    end

    context 'Condition 1: feature flag is disabled' do
      it 'returns false' do
        allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(false)
        builder.params = valid_params
        expect(builder.use_rollup?).to be false
      end
    end

    context 'Condition 2: metric is not covered' do
      it 'returns false for conversations_count' do
        builder.params = valid_params.merge(metric: 'conversations_count')

        expect(builder.use_rollup?).to be false
      end

      it 'returns false for incoming_messages_count' do
        builder.params = valid_params.merge(metric: 'incoming_messages_count')

        expect(builder.use_rollup?).to be false
      end

      it 'returns false for outgoing_messages_count' do
        builder.params = valid_params.merge(metric: 'outgoing_messages_count')

        expect(builder.use_rollup?).to be false
      end
    end

    context 'Condition 2: metric is covered' do
      it 'returns true for avg_first_response_time' do
        builder.params = valid_params.merge(metric: 'avg_first_response_time')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for avg_resolution_time' do
        builder.params = valid_params
        expect(builder.use_rollup?).to be true
      end

      it 'returns true for reply_time' do
        builder.params = valid_params.merge(metric: 'reply_time')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for resolutions_count' do
        builder.params = valid_params.merge(metric: 'resolutions_count')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for bot_resolutions_count' do
        builder.params = valid_params.merge(metric: 'bot_resolutions_count')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for bot_handoffs_count' do
        builder.params = valid_params.merge(metric: 'bot_handoffs_count')

        expect(builder.use_rollup?).to be true
      end
    end

    context 'Condition 3: group_by is hourly' do
      it 'returns false when group_by is hour' do
        builder.params = valid_params.merge(group_by: 'hour')
        expect(builder.use_rollup?).to be false
      end

      it 'returns true for day granularity' do
        builder.params = valid_params
        expect(builder.use_rollup?).to be true
      end

      it 'returns true for week granularity' do
        builder.params = valid_params.merge(group_by: 'week')
        expect(builder.use_rollup?).to be true
      end

      it 'returns true for month granularity' do
        builder.params = valid_params.merge(group_by: 'month')
        expect(builder.use_rollup?).to be true
      end

      it 'returns true for year granularity' do
        builder.params = valid_params.merge(group_by: 'year')
        expect(builder.use_rollup?).to be true
      end
    end

    context 'Condition 4: dimension is not supported' do
      it 'returns false for label dimension' do
        builder.params = valid_params.merge(type: 'label')

        expect(builder.use_rollup?).to be false
      end

      it 'returns true for account dimension' do
        builder.params = valid_params.merge(type: 'account')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for agent dimension' do
        builder.params = valid_params.merge(type: 'agent')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for inbox dimension' do
        builder.params = valid_params.merge(type: 'inbox')

        expect(builder.use_rollup?).to be true
      end

      it 'returns true for team dimension' do
        builder.params = valid_params.merge(type: 'team')

        expect(builder.use_rollup?).to be true
      end
    end

    context 'Condition 5: timezone_offset does not match' do
      it 'returns false when timezone_offset is UTC instead of EST' do
        builder.params = valid_params.merge(timezone_offset: 0)

        expect(builder.use_rollup?).to be false
      end

      it 'returns false when timezone_offset is UTC+5:30 (different from EST)' do
        builder.params = valid_params.merge(timezone_offset: 5.5)

        expect(builder.use_rollup?).to be false
      end

      it 'returns true when timezone_offset matches account timezone' do
        builder.params = valid_params.merge(timezone_offset: -5)

        expect(builder.use_rollup?).to be true
      end

      it 'returns true when timezone_offset is blank (defaults to account timezone)' do
        builder.params = valid_params.merge(timezone_offset: nil)

        expect(builder.use_rollup?).to be true
      end
    end

    context 'when used from BaseSummaryBuilder (no params[:metric])' do
      it 'returns true because summary builders override metric_covered?' do
        builder.params = { type: 'agent', timezone_offset: -5 }

        # Without the override, this would return false since params[:metric] is blank
        expect(builder.use_rollup?).to be false

        # BaseSummaryBuilder overrides metric_covered? to always return true
        summary_builder_class = Class.new(dummy_class) do
          def metric_covered?
            true
          end
        end

        summary_builder = summary_builder_class.new
        summary_builder.account = account
        summary_builder.params = { type: 'agent', timezone_offset: -5, group_by: 'day' }
        expect(summary_builder.use_rollup?).to be true
      end
    end
  end

  describe '#metric_to_rollup_metric' do
    it 'maps avg_resolution_time to resolution_time' do
      builder.params = { metric: 'avg_resolution_time' }
      expect(builder.metric_to_rollup_metric('avg_resolution_time')).to eq(:resolution_time)
    end

    it 'maps avg_first_response_time to first_response' do
      builder.params = { metric: 'avg_first_response_time' }
      expect(builder.metric_to_rollup_metric('avg_first_response_time')).to eq(:first_response)
    end

    it 'maps reply_time to reply_time' do
      builder.params = { metric: 'reply_time' }
      expect(builder.metric_to_rollup_metric('reply_time')).to eq(:reply_time)
    end

    it 'maps resolutions_count to resolutions_count' do
      builder.params = { metric: 'resolutions_count' }
      expect(builder.metric_to_rollup_metric('resolutions_count')).to eq(:resolutions_count)
    end

    it 'maps bot_resolutions_count to bot_resolutions_count' do
      builder.params = { metric: 'bot_resolutions_count' }
      expect(builder.metric_to_rollup_metric('bot_resolutions_count')).to eq(:bot_resolutions_count)
    end

    it 'maps bot_handoffs_count to bot_handoffs_count' do
      builder.params = { metric: 'bot_handoffs_count' }
      expect(builder.metric_to_rollup_metric('bot_handoffs_count')).to eq(:bot_handoffs_count)
    end
  end

  describe '#dimension_type_to_rollup' do
    it 'maps account type to account' do
      builder.params = { type: 'account' }
      expect(builder.dimension_type_to_rollup).to eq(:account)
    end

    it 'maps agent type to agent' do
      builder.params = { type: 'agent' }
      expect(builder.dimension_type_to_rollup).to eq(:agent)
    end

    it 'maps inbox type to inbox' do
      builder.params = { type: 'inbox' }
      expect(builder.dimension_type_to_rollup).to eq(:inbox)
    end

    it 'maps team type to team' do
      builder.params = { type: 'team' }
      expect(builder.dimension_type_to_rollup).to eq(:team)
    end

    it 'returns nil for unsupported type' do
      builder.params = { type: 'label' }
      expect(builder.dimension_type_to_rollup).to be_nil
    end

    it 'returns nil when type is blank' do
      builder.params = { type: nil }
      expect(builder.dimension_type_to_rollup).to be_nil
    end
  end
end
