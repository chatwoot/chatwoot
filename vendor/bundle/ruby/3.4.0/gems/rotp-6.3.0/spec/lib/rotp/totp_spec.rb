require 'spec_helper'

TEST_TIME = Time.utc 2016, 9, 23, 9 # 2016-09-23 09:00:00 UTC
TEST_TOKEN = '082630'.freeze
TEST_SECRET = 'JBSWY3DPEHPK3PXP'

RSpec.describe ROTP::TOTP do
  let(:now)   { TEST_TIME }
  let(:token) { TEST_TOKEN }
  let(:totp)  { ROTP::TOTP.new TEST_SECRET }

  describe '#at' do
    let(:token) { totp.at now }

    it 'is a string number' do
      expect(token).to eq TEST_TOKEN
    end

    context 'RFC compatibility' do
      let(:totp) { ROTP::TOTP.new('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ') }

      it 'matches the RFC documentation examples' do
        expect(totp.at(1_111_111_111)).to eq '050471'
        expect(totp.at(1_234_567_890)).to eq '005924'
        expect(totp.at(2_000_000_000)).to eq '279037'
      end
    end
  end

  describe '#verify' do
    let(:verification) { totp.verify token, at: now }

    context 'numeric token' do
      let(:token) { 82_630 }

      it 'raises an error with an integer' do
        expect { verification }.to raise_error(ArgumentError)
      end
    end

    context 'unpadded string token' do
      let(:token) { '82630' }

      it 'fails to verify' do
        expect(verification).to be_falsey
      end
    end

    context 'correctly padded string token' do
      it 'verifies' do
        expect(verification).to be_truthy
      end
    end

    context 'RFC compatibility' do
      let(:totp) { ROTP::TOTP.new 'wrn3pqx5uqxqvnqr' }

      before do
        Timecop.freeze now
      end

      context 'correct time based OTP' do
        let(:token) { '102705' }
        let(:now)   { Time.at 1_297_553_958 }

        it 'verifies' do
          expect(totp.verify('102705')).to be_truthy
        end
      end

      context 'wrong time based OTP' do
        it 'fails to verify' do
          expect(totp.verify('102705')).to be_falsey
        end
      end
    end
    context 'invalidating reused tokens' do
      let(:verification) do
        totp.verify token,
                    after: after,
                    at: now
      end
      let(:after) { nil }

      context 'passing in the `after` timestamp' do
        let(:after) do
          totp.verify TEST_TOKEN, after: nil, at: now
        end

        it 'returns a timecode' do
          expect(after).to be_kind_of(Integer)
          expect(after).to be_within(30).of(now.to_i)
        end

        context 'reusing same token' do
          it 'is false' do
            expect(verification).to be_falsy
          end
        end
      end
    end
  end

  def get_timecodes(at, b, a)
    # Test the private method
    totp.send('get_timecodes', at, b, a)
  end

  describe 'drifting timecodes' do
    it 'should get timecodes behind' do
      expect(get_timecodes(TEST_TIME + 15, 15, 0)).to eq([49_154_040])
      expect(get_timecodes(TEST_TIME, 15, 0)).to eq([49_154_039, 49_154_040])
      expect(get_timecodes(TEST_TIME, 40, 0)).to eq([49_154_038, 49_154_039, 49_154_040])
      expect(get_timecodes(TEST_TIME, 90, 0)).to eq([49_154_037, 49_154_038, 49_154_039, 49_154_040])
    end
    it 'should get timecodes ahead' do
      expect(get_timecodes(TEST_TIME, 0, 15)).to eq([49_154_040])
      expect(get_timecodes(TEST_TIME + 15, 0, 15)).to eq([49_154_040, 49_154_041])
      expect(get_timecodes(TEST_TIME, 0, 30)).to eq([49_154_040, 49_154_041])
      expect(get_timecodes(TEST_TIME, 0, 70)).to eq([49_154_040, 49_154_041, 49_154_042])
      expect(get_timecodes(TEST_TIME, 0, 90)).to eq([49_154_040, 49_154_041, 49_154_042, 49_154_043])
    end
    it 'should get timecodes behind and ahead' do
      expect(get_timecodes(TEST_TIME, 30, 30)).to eq([49_154_039, 49_154_040, 49_154_041])
      expect(get_timecodes(TEST_TIME, 60, 60)).to eq([49_154_038, 49_154_039, 49_154_040, 49_154_041, 49_154_042])
    end
  end

  describe '#verify with drift' do
    let(:verification) { totp.verify token, drift_ahead: drift_ahead, drift_behind: drift_behind, at: now }
    let(:drift_ahead) { 0 }
    let(:drift_behind) { 0 }

    context 'with an old OTP' do
      let(:token) { totp.at TEST_TIME - 30 } # Previous token at 2016-09-23 08:59:30 UTC
      let(:drift_behind) { 15 }

      # Tested at 2016-09-23 09:00:00 UTC, and with drift back to 2016-09-23 08:59:45 UTC
      # This would therefore include 2 intervals
      it 'inside of drift range' do
        expect(verification).to be_truthy
      end

      # Tested at 2016-09-23 09:00:20 UTC, and with drift back to 2016-09-23 09:00:05 UTC
      # This only includes 1 interval, therefore only the current token is valid
      context 'outside of drift range' do
        let(:now)   { TEST_TIME + 20 }

        it 'is nil' do
          expect(verification).to be_nil
        end
      end
    end

    context 'with a future OTP' do
      let(:token) { totp.at TEST_TIME + 30 } # The next valid token - 2016-09-23 09:00:30 UTC
      let(:drift_ahead) { 15 }

      # Tested at 2016-09-23 09:00:00 UTC, and ahead to 2016-09-23 09:00:15 UTC
      # This only includes 1 interval, therefore only the current token is valid
      it 'outside of drift range' do
        expect(verification).to be_falsey
      end
      # Tested at 2016-09-23 09:00:20 UTC, and with drift ahead to 2016-09-23 09:00:35 UTC
      # This would therefore include 2 intervals
      context 'inside of drift range' do
        let(:now) { TEST_TIME + 20 }

        it 'is true' do
          expect(verification).to be_truthy
        end
      end
    end
  end

  describe '#verify with drift and prevent token reuse' do
    let(:verification) { totp.verify token, drift_ahead: drift_ahead, drift_behind: drift_behind, after: after, at: now }
    let(:drift_ahead) { 0 }
    let(:drift_behind) { 0 }
    let(:after) { nil }

    context 'with the `after` timestamp set' do
      context 'older token' do
        let(:token) { totp.at TEST_TIME - 30 }
        let(:drift_behind) { 15 }

        it 'is true' do
          expect(verification).to be_truthy
          expect(verification).to eq((TEST_TIME - 30).to_i)
        end

        context 'after it has been used' do
          let(:after) do
            totp.verify token, after: nil, at: now, drift_behind: drift_behind
          end
          it 'is false' do
            expect(verification).to be_falsey
          end
        end
      end

      context 'newer token' do
        let(:token) { totp.at TEST_TIME + 30 }
        let(:drift_ahead) { 15 }
        let(:now) { TEST_TIME + 15 }

        it 'is true' do
          expect(verification).to be_truthy
          expect(verification).to eq((TEST_TIME + 30).to_i)
        end

        context 'after it has been used' do
          let(:after) do
            totp.verify token, after: nil, at: now, drift_ahead: drift_ahead
          end
          it 'is false' do
            expect(verification).to be_falsey
          end
        end
      end
    end
  end


  describe '#provisioning_uri' do
    let(:params) { CGI.parse URI.parse(uri).query }

    context "with a provided name on the TOTP instance" do
      let(:totp) { ROTP::TOTP.new(TEST_SECRET, name: "m@mdp.im") }
      it 'creates a provisioning uri from the OTP instance' do
        expect(totp.provisioning_uri())
          .to eq 'otpauth://totp/m%40mdp.im?secret=JBSWY3DPEHPK3PXP'
      end

      it 'allow passing a name to override the OTP name' do
        expect(totp.provisioning_uri('mark@percival'))
          .to eq 'otpauth://totp/mark%40percival?secret=JBSWY3DPEHPK3PXP'
      end
    end

    context 'with non-standard provisioning_params' do
      let(:totp)    {
        ROTP::TOTP.new(TEST_SECRET,
          provisioning_params: { image: 'https://example.com/icon.png' }
        )
      }
      let(:uri)    { totp.provisioning_uri("mark@percival") }

      it 'includes the issuer as parameter' do
        expect(params['image'].first).to eq 'https://example.com/icon.png'
      end

    end

    context "with an issuer" do
      let(:totp) { ROTP::TOTP.new(TEST_SECRET, name: "m@mdp.im", issuer: "Example.com") }

      it 'creates a provisioning uri from the OTP instance' do
        expect(totp.provisioning_uri())
          .to eq 'otpauth://totp/Example.com:m%40mdp.im?secret=JBSWY3DPEHPK3PXP&issuer=Example.com'
      end

      it 'allow passing a name to override the OTP name' do
        expect(totp.provisioning_uri('mark@percival'))
          .to eq 'otpauth://totp/Example.com:mark%40percival?secret=JBSWY3DPEHPK3PXP&issuer=Example.com'
      end

    end

  end

  describe '#now' do
    before do
      Timecop.freeze now
    end

    context 'Google Authenticator' do
      let(:totp) { ROTP::TOTP.new 'wrn3pqx5uqxqvnqr' }
      let(:now)  { Time.at 1_297_553_958 }

      it 'matches the known output' do
        expect(totp.now).to eq '102705'
      end
    end

    context 'Dropbox 26 char secret output' do
      let(:totp) { ROTP::TOTP.new 'tjtpqea6a42l56g5eym73go2oa' }
      let(:now)  { Time.at 1_378_762_454 }

      it 'matches the known output' do
        expect(totp.now).to eq '747864'
      end
    end
  end
end
