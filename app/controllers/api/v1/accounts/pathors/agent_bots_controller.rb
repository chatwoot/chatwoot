# Lists the Pathors agent bots this account can put behind a voice inbox, so the
# wizard can ask who answers the call. The bot carries the project id that
# Pathors routes the number to, and that id is all the dashboard needs — the
# `outgoing_url` it is parsed from stays on the server.
class Api::V1::Accounts::Pathors::AgentBotsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    render json: { payload: pathors_agent_bots }
  end

  private

  # A bot whose callback URL does not parse into a project cannot answer a call,
  # so it is not an option to offer.
  def pathors_agent_bots
    Current.account.agent_bots
           .where('outgoing_url LIKE ?', "%#{Integrations::App::PATHORS_CALLBACK_URL_FRAGMENT}%")
           .order(:id)
           .filter_map do |bot|
             project_id = bot.pathors_project_id
             { id: bot.id, name: bot.name, project_id: project_id } if project_id.present?
           end
  end

  # Picking the answering agent is part of creating a voice inbox, so it carries
  # the same admin gate.
  def check_authorization
    authorize(:inbox, :create?)
  end
end
