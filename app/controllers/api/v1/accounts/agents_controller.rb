class Api::V1::Accounts::AgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :find_user, only: [:create]
  before_action :validate_limit, only: [:create]
  before_action :create_user, only: [:create]
  before_action :save_account_user, only: [:create]

  def index
    @agents = agents
  end

  def create; end

  def update
    @agent.update!(agent_params.slice(:name).compact)
    @agent.current_account_user.update!(agent_params.slice(:role, :availability, :auto_offline).compact)
  end

  def destroy
    @agent.current_account_user.destroy
    head :ok
  end

  private

  def check_authorization
    super(User)
  end

  def fetch_agent
    @agent = agents.find(params[:id])
  end

  def find_user
    @user =  User.find_by(email: new_agent_params[:email])
  end

  # TODO: move this to a builder and combine the save account user method into a builder
  # ensure the account user association is also created in a single transaction
  def create_user
    return if @user

    @user = User.create!(new_agent_params.slice(:email, :name, :password, :password_confirmation))
  end

  def save_account_user
    AccountUser.create!({
      account_id: Current.account.id,
      user_id: @user.id,
      inviter_id: current_user.id
    }.merge({
      role: new_agent_params[:role],
      availability: new_agent_params[:availability],
      auto_offline: new_agent_params[:auto_offline]
    }.compact))
  end

  def agent_params
    params.require(:agent).permit(:name, :email, :name, :role, :availability, :auto_offline)
  end

  def new_agent_params
    # intial string ensures the password requirements are met
    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    params.require(:agent).permit(:email, :name, :role, :availability, :auto_offline)
          .merge!(password: temp_password, password_confirmation: temp_password, inviter: current_user)
  end

  def agents
    @agents ||= Current.account.users.order_by_full_name.includes({ avatar_attachment: [:blob] })
  end

  def validate_limit
    render_payment_required('Account limit exceeded. Upgrade to a higher plan') if agents.count >= Current.account.usage_limits[:agents]
  end
end
