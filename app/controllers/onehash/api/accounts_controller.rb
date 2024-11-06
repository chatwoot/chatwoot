class Onehash::Api::AccountsController < Onehash::IntegrationController
  def index
    user = User.from_email(params[:email])

    return render json: { error: 'User not found' }, status: :not_found if user.nil?

    accounts = user.accounts

    render json: accounts, status: :ok
  end
end
