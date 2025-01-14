class Onehash::Cal::ActionController < Onehash::IntegrationController
  before_action :validate_create_params, only: :create
  before_action :validate_destroy_params, only: :destroy
  before_action :initialize_current_account_user, only: :create


  def create
    # Check if an integration hook already exists for the given app_id and account_user_id
    if Integrations::Hook.exists?(app_id: 'onehash_cal', account_user_id: Current.account_user.id)
      render json: { error: 'Some other account already linked' }, status: :unprocessable_entity
      return
    end
    create_hook(params[:cal_user_id])
    render json: { message: 'Account User hooks created successfully' }, status: :ok
  end

  def destroy
    account_user_id = params[:id]
    account_user = AccountUser.find_by(id: account_user_id)
    Integrations::Hook.where(account_user_id: account_user.id, app_id: 'onehash_cal').destroy_all
    render json: { message: 'Account User hooks deleted successfully' }, status: :ok
  end

  private

  def validate_create_params
    return if params[:account_user_id].present? && params[:cal_user_id].present?

    render json: { error: 'account_user_id and cal_user_id are required' }, status: :bad_request
  end

  def validate_destroy_params
    return if params[:id].present?

    render json: { error: 'Account User Id is required' }, status: :bad_request
  end
  
  def initialize_current_account_user
    init_current_account_user(params[:account_user_id])
  end

  def init_current_account_user(account_user_id)
    if account_user_id.present?
      begin
        Current.account_user = AccountUser.find(account_user_id)
        logger.info "Set Current.account_user to ID #{account_user_id}"
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Account User not found for #{account_user_id}" }, status: :bad_request
      end
    else
      logger.warn 'No account_user_id found in the state parameter. Unable to set Current.account_user.'
    end
  end
  

  def create_hook(cal_user_id)
    Integrations::Hook.create(
      access_token: '',
      hook_type: 'account_user',
      account_user: Current.account_user,
      account: Current.account_user.account,
      inbox_id: nil,
      app_id: 'onehash_cal',
      settings: { cal_user_id: cal_user_id },
      status: 'enabled'
    )
  end
end
