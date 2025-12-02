class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:limits, :toggle_deletion]

  def subscription
    head :no_content
  end

  def limits
    limits = {
      'conversation' => {},
      'non_web_inboxes' => {},
      'agents' => {
        'allowed' => ChatwootApp.max_limit,
        'consumed' => agents(@account)
      },
      'captain' => {
        'documents' => {
          'total_count' => ChatwootApp.max_limit,
          'current_available' => ChatwootApp.max_limit,
          'consumed' => 0
        },
        'responses' => {
          'total_count' => ChatwootApp.max_limit,
          'current_available' => ChatwootApp.max_limit,
          'consumed' => 0
        }
      }
    }

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def checkout
    render json: { message: 'Billing is disabled in this version' }, status: :ok
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  private

  def check_cloud_env
    # Allow in all environments for this community edition
    true
  end

  def default_limits
    # Not used anymore
    {}
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def create_stripe_billing_session(customer_id)
    # No-op
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
