require 'spec_helper'
require 'rotp/cli'

RSpec.describe ROTP::CLI do
  let(:cli)    { described_class.new('executable', argv) }
  let(:output) { cli.output }
  let(:now)    { Time.utc 2012, 1, 1 }

  before do
    Timecop.freeze now
  end

  context 'generating a TOTP' do
    let(:argv) { %w[--secret JBSWY3DPEHPK3PXP] }

    it 'prints the corresponding token' do
      expect(output).to eq '068212'
    end
  end

  context 'generating a TOTP with sha256 digest' do
    let(:argv) { %w[--secret JBSWY3DPEHPK3PXP --digest sha256] }

    it 'prints the corresponding token' do
      expect(output).to eq '544902'
    end
  end

  context 'generating a TOTP with no secret' do
    let(:argv) { %w[--time --secret] }

    it 'prints the corresponding token' do
      expect(output).to match 'You must also specify a --secret'
    end
  end

  context 'generating a TOTP with bad base32 secret' do
    let(:argv) { %W[--time --secret #{'1' * 32}] }

    it 'prints the corresponding token' do
      expect(output).to match 'Secret must be in RFC4648 Base32 format'
    end
  end

  context 'trying to generate an unsupport type' do
    let(:argv) { %W[--notreal --secret #{'a' * 32}] }

    it 'prints the corresponding token' do
      expect(output).to match 'invalid option: --notreal'
    end
  end

  context 'generating a HOTP' do
    let(:argv) { %W[--hmac --secret #{'a' * 32} --counter 1234] }

    it 'prints the corresponding token' do
      expect(output).to eq '161024'
    end
  end

  context 'generating a HOTP' do
    let(:argv) { %W[--hmac --secret #{'a' * 32} --counter 1234 --digest sha256] }

    it 'prints the corresponding token' do
      expect(output).to eq '325941'
    end
  end
end
