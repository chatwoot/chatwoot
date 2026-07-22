class Api::V1::Accounts::Captain::AgentSessionsController < Api::V1::Accounts::BaseController
  before_action :set_message
  before_action :authorize_conversation

  def show
    @agent_session = Current.account.captain_agent_sessions.find_by(result_type: 'Message', result_id: @message.id)
    return head :not_found if @agent_session.blank?

    @citations = Current.account.captain_assistant_responses
                        .where(id: @agent_session.faq_ids)
                        .includes(:documentable)
    @scenario_titles = Captain::Scenario.where(account_id: Current.account.id, id: @agent_session.scenario_ids)
                                        .pluck(:id, :title).to_h
  end

  private

  def set_message
    @message = Current.account.messages.find(params[:id])
  end

  def authorize_conversation
    authorize @message.conversation, :show?
  end
end
