class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    render json: { error: I18n.t('errors.assignment.permission') }, status: :forbidden and return unless permission?

    if Current.account.change_from_request? && need_change_request?
      set_requesting_assignee
      send_mention_note
      render json: { error: I18n.t('errors.assignment.change_requested') }, status: :forbidden
    elsif params.key?(:assignee_id)
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  def agree_to_request
    @agent = @conversation.requesting_assignee
    @conversation.assignee = @agent
    @conversation.requesting_assignee = nil
    @conversation.save!
    render_agent
  end

  def cancel_request
    @conversation.requesting_assignee = nil
    @conversation.save!
    render partial: 'api/v1/conversations/partials/conversation', formats: [:json], locals: { conversation: @conversation }
  end

  private

  def set_agent
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.assignee = @agent
    @conversation.save!
    render_agent
  end

  def render_agent
    if @agent.nil?
      render json: nil
    else
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: @agent }
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end

  def permission?
    return true if Current.account.no_restriction?

    return restriction? if Current.account.restriction?

    return change_from_request? if Current.account.change_from_request?
  end

  def restriction?
    # admin user, or leader of the team of current inbox can change
    return true if Current.user.administrator? || Current.user == @conversation.inbox.team&.leader

    # everyone can assign to themselves if the conversation doesn't have assignee yet
    return true if @conversation.assignee.blank? && params[:assignee_id].present? && Current.user.id == params[:assignee_id].to_i

    false
  end

  def change_from_request?
    # admin user, or leader of the team of current inbox can change anything
    return true if Current.user.administrator? || Current.user == @conversation.inbox.team&.leader

    # assigning or changing to others is not allowed with normal users
    return false if Current.user.id != params[:assignee_id].to_i

    # changing from themselves to others is not allowed too
    return false if Current.user == @conversation.assignee && params[:assignee_id].present?

    # the rest are fine to continue with the checking of need_change_request
    true
  end

  def need_change_request?
    return false if @conversation.assignee.blank? && params[:assignee_id].present? && Current.user.id == params[:assignee_id].to_i

    return false if Current.user.administrator? || Current.user == @conversation.inbox.team&.leader

    true
  end

  def set_requesting_assignee
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.requesting_assignee = @agent
    @conversation.save!
  end

  def send_mention_note
    message_params =
      {
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        sender_id: Current.user.id,
        content: generate_mention_content,
        message_type: :outgoing,
        private: true
      }
    @conversation.messages.create!(message_params)
  end

  def generate_mention_content
    user_id = @conversation.assignee.id
    name = @conversation.assignee.name
    encoded_name = URI.encode_www_form_component(name)
    message = I18n.t('errors.assignment.change_request_note')
    "[@#{name}](mention://user/#{user_id}/#{encoded_name}) #{message}"
  end
end
