class Api::V1::AgentsController < Api::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :find_user, only: [:create]
  before_action :create_user, only: [:create]
  before_action :save_account_user, only: [:create]

  def index
    @agents = agents
  end

  def destroy
    @agent.account_user.destroy
    head :ok
  end

  def update
    @agent.update!(agent_params.except(:role))
    @agent.account_user.update!(role: agent_params[:role]) if agent_params[:role]
    render 'api/v1/models/user.json', locals: { resource: @agent }
  end

  def create
    render 'api/v1/models/user.json', locals: { resource: @user }
  end

  private

  def check_authorization
    authorize(User)
  end

  def fetch_agent
    @agent = agents.find(params[:id])
  end

  def find_user
    @user =  User.find_by(email: new_agent_params[:email])
  end

  def create_user
    return if @user

    @user = User.create!(new_agent_params.slice(:email, :name, :password, :password_confirmation))
  end

  def save_account_user
    AccountUser.create!(
      account_id: current_account.id,
      user_id: @user.id,
      role: new_agent_params[:role],
      inviter_id: current_user.id
    )
  end

  def agent_params
    params.require(:agent).permit(:email, :name, :role)
  end

  def new_agent_params
    time = Time.now.to_i
    params.require(:agent).permit(:email, :name, :role)
          .merge!(password: time, password_confirmation: time, inviter: current_user)
  end

  def agents
    @agents ||= current_account.users
  end
end
