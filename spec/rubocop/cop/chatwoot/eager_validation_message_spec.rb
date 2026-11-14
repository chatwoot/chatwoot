require 'rails_helper'
require Rails.root.join('rubocop/eager_validation_message').to_s
require 'rubocop/rspec/support'

RSpec.describe RuboCop::Cop::Chatwoot::EagerValidationMessage, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'flags I18n.t nested in a validator option' do
    expect_offense(<<~RUBY)
      validates :email, format: { with: /@/, message: I18n.t('errors.contacts.email.invalid') }
                                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Pass `message: ->(*) { I18n.t(...) }`; `I18n.t` here runs once, at class load.
    RUBY
  end

  it 'flags the fully qualified constant' do
    expect_offense(<<~RUBY)
      validates :title, presence: { message: ::I18n.translate('errors.validations.presence') }
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Pass `message: ->(*) { I18n.t(...) }`; `I18n.t` here runs once, at class load.
    RUBY
  end

  it 'leaves a lazy message alone' do
    expect_no_offenses(<<~RUBY)
      validates :email, format: { with: /@/, message: ->(*) { I18n.t('errors.contacts.email.invalid') } }
    RUBY
  end

  it 'leaves I18n.t at call time alone' do
    expect_no_offenses(<<~RUBY)
      def check_inbox
        errors.add(:inbox, message: I18n.t('errors.inbox.invalid'))
      end
    RUBY
  end
end
