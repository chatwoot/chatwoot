require 'spec_helper'
require 'active_model'

class TwoFactorAuthenticatableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  # stub out the ::ActiveRecord::Encryption::EncryptableRecord API
  attr_accessor :otp_secret
  def self.encrypts(*attrs)
    nil
  end

  define_model_callbacks :update

  devise :two_factor_authenticatable

  attr_accessor :consumed_timestep

  def save!(_)
    # noop for testing
    true
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  it 'should be inserted prior to other devise modules' do
    expect(Devise::ALL.first).to eq(:two_factor_authenticatable)
  end

  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When clean_up_passwords is called ' do
    subject { TwoFactorAuthenticatableDouble.new }
    before :each do
      subject.otp_attempt = 'foo'
      subject.password_confirmation = 'foo'
    end
    it 'otp_attempt should be nill' do
      subject.clean_up_passwords
      expect(subject.otp_attempt).to be_nil
    end
    it 'password_confirmation should be nill' do
      subject.clean_up_passwords
      expect(subject.password_confirmation).to be_nil
    end
  end
end


