# frozen_string_literal: true

class AgentBuilder
  include CustomExceptions::Agent
  pattr_initialize %i[agent_params! current_user! current_account!]

  def perform
    ActiveRecord::Base.transaction do
      create_user
      save_account_user
      add_to_inboxes if @agent_params[:inbox_ids].present?
      add_to_teams if @agent_params[:team_ids].present?
    end
    @user
  rescue StandardError => e
    Rails.logger.error e.inspect
    raise e
  end

  private

  def create_user
    @user = User.find_by(email: @agent_params[:email])
    return @user.send_confirmation_instructions if @user

    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    @user = User.create!(
      email: @agent_params[:email],
      name: @agent_params[:name],
      password: temp_password,
      password_confirmation: temp_password
    )
  end

  def save_account_user
    AccountUser.create!({
      account_id: @current_account.id,
      user_id: @user.id,
      inviter_id: @current_user.id,
      role: @agent_params[:role],
      availability: @agent_params[:availability],
      auto_offline: @agent_params[:auto_offline]
    }.compact)
  end

  def add_to_inboxes
    inboxes = @current_account.inboxes.where(id: @agent_params[:inbox_ids])
    inboxes.each do |inbox|
      inbox.add_member(@user.id)
    end
  end

  def add_to_teams
    teams = @current_account.teams.where(id: @agent_params[:team_ids])
    teams.each do |team|
      team.add_member(@user.id)
    end
  end
end
