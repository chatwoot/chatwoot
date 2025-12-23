require 'spec_helper'

RSpec.describe ROTP::HOTP do
  let(:counter) { 1234 }
  let(:token)   { '161024' }
  let(:hotp)    { ROTP::HOTP.new('a' * 32) }

  describe '#at' do
    let(:token) { hotp.at counter }

    context 'only the counter as argument' do
      it 'generates a string OTP' do
        expect(token).to eq '161024'
      end
    end

    context 'invalid counter' do
      it 'raises an error' do
        expect { hotp.at(-123_456) }.to raise_error(ArgumentError)
      end
    end

    context 'RFC compatibility' do
      let(:hotp) { ROTP::HOTP.new('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ') }

      it 'matches the RFC documentation examples' do
        # 12345678901234567890 in Base32
        # GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
        expect(hotp.at(0)).to eq '755224'
        expect(hotp.at(1)).to eq '287082'
        expect(hotp.at(2)).to eq '359152'
        expect(hotp.at(3)).to eq '969429'
        expect(hotp.at(4)).to eq '338314'
        expect(hotp.at(5)).to eq '254676'
        expect(hotp.at(6)).to eq '287922'
        expect(hotp.at(7)).to eq '162583'
        expect(hotp.at(8)).to eq '399871'
        expect(hotp.at(9)).to eq '520489'
      end
    end
  end

  describe '#verify' do
    let(:verification) { hotp.verify token, counter }

    context 'numeric token' do
      let(:token) { 161_024 }

      it 'raises an error' do
        expect { verification }.to raise_error(ArgumentError)
      end
    end

    context 'string token' do
      it 'is true' do
        expect(verification).to be_truthy
      end
    end

    context 'RFC compatibility' do
      let(:hotp)  { ROTP::HOTP.new('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ') }
      let(:token) { '520489' }

      it 'verifies and does not allow reuse' do
        expect(hotp.verify(token, 9)).to be_truthy
        expect(hotp.verify(token, 10)).to be_falsey
      end
    end
    describe 'with retries' do
      let(:verification) { hotp.verify token, counter, retries: retries }

      context 'counter outside than retries' do
        let(:counter) { 1223 }
        let(:retries) { 10 }

        it 'is false' do
          expect(verification).to be_falsey
        end
      end

      context 'counter exactly in retry range' do
        let(:counter) { 1224 }
        let(:retries) { 10 }

        it 'is true' do
          expect(verification).to eq 1234
        end
      end

      context 'counter in retry range' do
        let(:counter) { 1224 }
        let(:retries) { 11 }

        it 'is true' do
          expect(verification).to eq 1234
        end
      end

      context 'counter ahead of token' do
        let(:counter) { 1235 }
        let(:retries) { 3 }

        it 'is false' do
          expect(verification).to be_falsey
        end
      end
    end
  end

  describe '#provisioning_uri' do
    let(:hotp) { ROTP::HOTP.new('a' * 32, name: "m@mdp.im") }
    let(:params) { CGI.parse URI.parse(uri).query }

    it 'created from the otp instance data' do
      expect(hotp.provisioning_uri())
        .to eq 'otpauth://hotp/m%40mdp.im?secret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&counter=0'
    end

    it 'allow passing a name to override the OTP name' do
      expect(hotp.provisioning_uri('mark@percival'))
        .to eq 'otpauth://hotp/mark%40percival?secret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&counter=0'
    end

    it 'also accepts a custom counter value' do
      expect(hotp.provisioning_uri('mark@percival', 17))
        .to eq 'otpauth://hotp/mark%40percival?secret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&counter=17'
    end

    context 'with non-standard provisioning_params' do
      let(:hotp) { ROTP::HOTP.new('a' * 32, digits: 8, provisioning_params: {image: 'https://example.com/icon.png'}) }
      let(:uri)    { hotp.provisioning_uri("mark@percival") }

      it 'includes the issuer as parameter' do
        expect(params['image'].first).to eq 'https://example.com/icon.png'
      end
    end

    context "with an issuer" do
      let(:hotp) { ROTP::HOTP.new('a' * 32, name: "m@mdp.im", issuer: "Example.com") }

      it 'created from the otp instance data' do
        expect(hotp.provisioning_uri())
          .to eq 'otpauth://hotp/Example.com:m%40mdp.im?secret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&issuer=Example.com&counter=0'
      end

      it 'allow passing a name to override the OTP name' do
        expect(hotp.provisioning_uri('mark@percival'))
          .to eq 'otpauth://hotp/Example.com:mark%40percival?secret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa&issuer=Example.com&counter=0'
      end
    end

  end
end
