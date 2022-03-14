class Api::V1::Accounts::BaseController < Api::BaseController
  include SwitchLocale
  before_action :current_account
  around_action :switch_locale_using_account_locale
end
