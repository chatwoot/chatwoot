require 'spec_helper'
require 'active_model'

class TwoFactorBackupableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  # stub out the ::ActiveRecord::Encryption::EncryptableRecord API
  attr_accessor :otp_secret
  def self.encrypts(*attrs)
    nil
  end

  define_model_callbacks :update

  devise :two_factor_authenticatable, :two_factor_backupable

  attr_accessor :otp_backup_codes

  def save!(_)
    true
  end
end

describe ::Devise::Models::TwoFactorBackupable do
  context 'When included in a class' do
    subject { TwoFactorBackupableDouble.new }

    it_behaves_like 'two_factor_backupable'
  end
end
