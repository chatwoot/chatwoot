# Lets the voice inbox wizard show the numbers this account's Pathors project
# owns, so an administrator picks a real number instead of typing one in.
#
# Unlike its siblings in this namespace this endpoint is for the dashboard, not
# for the Pathors backend, so it stays out of the bot-token allowlist.
class Api::V1::Accounts::Pathors::PhoneNumbersController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    render json: { payload: Pathors::PhoneNumbersService.new(account: Current.account).list }
  rescue CustomExceptions::Pathors::IntegrationNotConnected
    render json: { error: 'integration_not_connected' }, status: :not_found
  end

  private

  # Picking a number is the first step of creating a voice inbox, so it carries
  # the same admin gate.
  def check_authorization
    authorize(:inbox, :create?)
  end
end
