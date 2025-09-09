require 'rails_helper'

RSpec.describe SessionManageable do
  let(:user) { create(:user) }
  let(:current_time) { Time.current.to_i }
  let(:expired_time) { 1.hour.ago.to_i }
  let(:future_time) { 1.hour.from_now.to_i }

  before do
    # Mock GlobalConfig for session limit
    allow(GlobalConfig).to receive(:get).with(
      'USER_SESSION_LIMIT',
      'USER_SESSION_LIMIT_PER_USER',
      account: nil
    ).and_return('5')
  end

  describe '#logout_all_sessions!' do
    it 'clears all tokens and saves the user' do
      user.tokens = {
        'client1' => { 'token' => 'hashed_token_1', 'expiry' => future_time },
        'client2' => { 'token' => 'hashed_token_2', 'expiry' => future_time }
      }

      expect(user).to receive(:save!)
      user.logout_all_sessions!

      expect(user.tokens).to eq({})
    end

    it 'works with empty tokens' do
      user.tokens = {}
      expect(user).to receive(:save!)
      user.logout_all_sessions!
      expect(user.tokens).to eq({})
    end

    it 'works with nil tokens' do
      user.tokens = nil
      expect(user).to receive(:save!)
      user.logout_all_sessions!
      expect(user.tokens).to eq({})
    end
  end

  describe '#logout_session!' do
    before do
      user.tokens = {
        'client1' => { 'token' => 'hashed_token_1', 'expiry' => future_time },
        'client2' => { 'token' => 'hashed_token_2', 'expiry' => future_time }
      }
    end

    it 'removes specific client token and saves' do
      expect(user).to receive(:save!)
      result = user.logout_session!('client1')

      expect(result).to be true
      expect(user.tokens).not_to have_key('client1')
      expect(user.tokens).to have_key('client2')
    end

    it 'returns false for non-existent client' do
      result = user.logout_session!('non_existent_client')
      expect(result).to be false
    end

    it 'returns false for empty client_id' do
      result = user.logout_session!('')
      expect(result).to be false

      result = user.logout_session!(nil)
      expect(result).to be false
    end

    it 'returns false when no tokens present' do
      user.tokens = nil
      result = user.logout_session!('client1')
      expect(result).to be false
    end
  end

  describe '#reset_tokens_before!' do
    before do
      user.tokens = {
        'expired_client' => { 'token' => 'token1', 'expiry' => expired_time },
        'current_client' => { 'token' => 'token2', 'expiry' => future_time },
        'edge_case_client' => { 'token' => 'token3', 'expiry' => current_time }
      }
    end

    it 'removes tokens that expired before the given timestamp' do
      expect(user).to receive(:save!)
      user.reset_tokens_before!(current_time)

      expect(user.tokens).not_to have_key('expired_client')
      expect(user.tokens).to have_key('current_client')
      expect(user.tokens).to have_key('edge_case_client')
    end

    it 'handles timestamp as Time object' do
      timestamp = Time.zone.at(current_time)
      expect(user).to receive(:save!)
      user.reset_tokens_before!(timestamp)

      expect(user.tokens).not_to have_key('expired_client')
      expect(user.tokens).to have_key('current_client')
    end

    it 'does nothing when no tokens present' do
      user.tokens = nil
      user.reset_tokens_before!(current_time)
      # tokens gets initialized to empty hash during the process
      expect(user.tokens).to eq({})
    end

    it 'handles tokens with missing expiry' do
      user.tokens = {
        'no_expiry_client' => { 'token' => 'token1' },
        'zero_expiry_client' => { 'token' => 'token2', 'expiry' => 0 }
      }

      expect(user).to receive(:save!)
      user.reset_tokens_before!(current_time)

      expect(user.tokens).to be_empty
    end
  end

  describe '#active_session_count' do
    it 'counts only non-expired tokens' do
      user.tokens = {
        'expired1' => { 'token' => 'token1', 'expiry' => expired_time },
        'active1' => { 'token' => 'token2', 'expiry' => future_time },
        'active2' => { 'token' => 'token3', 'expiry' => future_time },
        'expired2' => { 'token' => 'token4', 'expiry' => expired_time }
      }

      expect(user.active_session_count).to eq(2)
    end

    it 'returns 0 when no tokens present' do
      user.tokens = nil
      expect(user.active_session_count).to eq(0)

      user.tokens = {}
      expect(user.active_session_count).to eq(0)
    end

    it 'handles tokens with missing expiry' do
      user.tokens = {
        'no_expiry' => { 'token' => 'token1' },
        'active' => { 'token' => 'token2', 'expiry' => future_time }
      }

      expect(user.active_session_count).to eq(1)
    end
  end

  describe '#session_limit_exceeded?' do
    it 'returns true when active sessions exceed limit' do
      # Mock 3 session limit
      allow(GlobalConfig).to receive(:get).and_return('3')

      user.tokens = {
        'active1' => { 'token' => 'token1', 'expiry' => future_time },
        'active2' => { 'token' => 'token2', 'expiry' => future_time },
        'active3' => { 'token' => 'token3', 'expiry' => future_time },
        'active4' => { 'token' => 'token4', 'expiry' => future_time }
      }

      expect(user.session_limit_exceeded?).to be true
    end

    it 'returns false when within limit' do
      allow(GlobalConfig).to receive(:get).and_return('5')

      user.tokens = {
        'active1' => { 'token' => 'token1', 'expiry' => future_time },
        'active2' => { 'token' => 'token2', 'expiry' => future_time }
      }

      expect(user.session_limit_exceeded?).to be false
    end

    it 'handles infinite limit' do
      allow(GlobalConfig).to receive(:get).and_return(nil)

      user.tokens = {}
      (1..100).each do |i|
        user.tokens["client#{i}"] = { 'token' => "token#{i}", 'expiry' => future_time }
      end

      expect(user.session_limit_exceeded?).to be false
    end
  end

  describe '#session_info' do
    it 'returns session information sorted by expiry (newest first)' do
      earlier_time = 2.hours.from_now.to_i
      later_time = 3.hours.from_now.to_i

      user.tokens = {
        'client1' => { 'token' => 'token1', 'expiry' => earlier_time },
        'client2' => { 'token' => 'token2', 'expiry' => later_time }
      }

      sessions = user.session_info

      expect(sessions.size).to eq(2)
      expect(sessions[0][:client_id]).to eq('client2')
      expect(sessions[0][:expiry]).to eq(Time.zone.at(later_time))
      expect(sessions[1][:client_id]).to eq('client1')
      expect(sessions[1][:expiry]).to eq(Time.zone.at(earlier_time))
    end

    it 'returns empty array when no tokens' do
      user.tokens = nil
      expect(user.session_info).to eq([])

      user.tokens = {}
      expect(user.session_info).to eq([])
    end

    it 'handles tokens with missing expiry' do
      user.tokens = {
        'client1' => { 'token' => 'token1' },
        'client2' => { 'token' => 'token2', 'expiry' => future_time }
      }

      sessions = user.session_info

      expect(sessions.size).to eq(2)
      expect(sessions[0][:expiry]).to eq(Time.zone.at(future_time))
      expect(sessions[1][:expiry]).to eq(Time.zone.at(0))
    end
  end

  describe 'private methods' do
    describe '#session_limit' do
      it 'returns configured limit from GlobalConfig' do
        allow(GlobalConfig).to receive(:get).with(
          'USER_SESSION_LIMIT',
          'USER_SESSION_LIMIT_PER_USER',
          account: nil
        ).and_return('10')

        limit = user.send(:session_limit)
        expect(limit).to eq(10)
      end

      it 'returns infinity when no limit configured' do
        allow(GlobalConfig).to receive(:get).and_return(nil)

        limit = user.send(:session_limit)
        expect(limit).to eq(Float::INFINITY)
      end

      it 'memoizes the result' do
        allow(GlobalConfig).to receive(:get).and_return('5')

        # First call
        limit1 = user.send(:session_limit)
        # Second call should use memoized value
        limit2 = user.send(:session_limit)

        expect(limit1).to eq(limit2)
        expect(GlobalConfig).to have_received(:get).once
      end
    end
  end
end
