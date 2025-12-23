require 'spec_helper'

RSpec.describe ROTP::OTP::URI do
  it 'meets basic functionality' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP')
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%40google.com?secret=JBSWY3DPEHPK3PXP'
  end

  it 'includes issuer' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', issuer: 'Example')
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example'
  end

  it 'encodes the account name' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', issuer: 'Provider1')
    uri = described_class.new(otp, account_name: 'Alice Smith')
    expect(uri.to_s).to eq 'otpauth://totp/Provider1:Alice%20Smith?secret=JBSWY3DPEHPK3PXP&issuer=Provider1'
  end

  it 'encodes the issuer' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', issuer: 'Big Corporation')
    uri = described_class.new(otp, account_name: ' alice@bigco.com')
    expect(uri.to_s).to eq 'otpauth://totp/Big%20Corporation:%20alice%40bigco.com?secret=JBSWY3DPEHPK3PXP&issuer=Big%20Corporation'
  end

  it 'includes non-default SHA256 algorithm' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', digest: 'sha256')
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%40google.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256'
  end

  it 'includes non-default SHA512 algorithm' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', digest: 'sha512')
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%40google.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512'
  end

  it 'includes non-default 8 digits' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', digits: 8)
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%40google.com?secret=JBSWY3DPEHPK3PXP&digits=8'
  end

  it 'includes non-default period for TOTP' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', interval: 35)
    uri = described_class.new(otp, account_name: 'alice@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%40google.com?secret=JBSWY3DPEHPK3PXP&period=35'
  end

  it 'includes non-default counter for HOTP' do
    otp = ROTP::HOTP.new('JBSWY3DPEHPK3PXP')
    uri = described_class.new(otp, account_name: 'alice@google.com', counter: 17)
    expect(uri.to_s).to eq 'otpauth://hotp/alice%40google.com?secret=JBSWY3DPEHPK3PXP&counter=17'
  end

  it 'can include all parameters' do
    otp = ROTP::TOTP.new(
      'HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ',
      digest: 'sha512',
      digits: 8,
      interval: 60,
      issuer: 'ACME Co',
    )
    uri = described_class.new(otp, account_name: 'john.doe@email.com')
    expect(uri.to_s).to eq'otpauth://totp/ACME%20Co:john.doe%40email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA512&digits=8&period=60'
  end

  it 'strips leading and trailing whitespace from the issuer' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', issuer: '  Big Corporation  ')
    uri = described_class.new(otp, account_name: ' alice@bigco.com')
    expect(uri.to_s).to eq 'otpauth://totp/Big%20Corporation:%20alice%40bigco.com?secret=JBSWY3DPEHPK3PXP&issuer=Big%20Corporation'
  end

  it 'strips trailing whitespace from the account name' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP')
    uri = described_class.new(otp, account_name: '  alice@google.com  ')
    expect(uri.to_s).to eq 'otpauth://totp/%20%20alice%40google.com?secret=JBSWY3DPEHPK3PXP'
  end

  it 'replaces colons in the issuer with underscores' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP', issuer: 'Big:Corporation')
    uri = described_class.new(otp, account_name: 'alice@bigco.com')
    expect(uri.to_s).to eq 'otpauth://totp/Big_Corporation:alice%40bigco.com?secret=JBSWY3DPEHPK3PXP&issuer=Big_Corporation'
  end

  it 'replaces colons in the account name with underscores' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP')
    uri = described_class.new(otp, account_name: 'Alice:Smith')
    expect(uri.to_s).to eq 'otpauth://totp/Alice_Smith?secret=JBSWY3DPEHPK3PXP'
  end

  it 'handles email account names with sub-addressing' do
    otp = ROTP::TOTP.new('JBSWY3DPEHPK3PXP')
    uri = described_class.new(otp, account_name: 'alice+1234@google.com')
    expect(uri.to_s).to eq 'otpauth://totp/alice%2B1234%40google.com?secret=JBSWY3DPEHPK3PXP'
  end
end
