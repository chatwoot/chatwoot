class Api::V1::AgentsController < Api::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :build_agent, only: [:create]

  def index
    render json: agents
  end

  def destroy
    @agent.destroy
    head :ok
  end

  def update
    @agent.update!(agent_params)
    render json: @agent
  end

  def create
    @agent.save!
    render json: @agent
  end

  private

  def check_authorization
    authorize(User)
  end

  def fetch_agent
    @agent = agents.find(params[:id])
  end

  def build_agent
    @agent = agents.new(new_agent_params)
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
