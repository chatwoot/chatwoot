class Api::V1::Accounts::ApplicationsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_application, only: [:show, :update, :destroy, :launch, :update_last_used]

  def index
    @applications = Current.account.applications.order(:name)
  end

  def show; end

  def create
    @application = Current.account.applications.build(application_params)

    if @application.save
      render :show, status: :created
    else
      render json: { errors: @application.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @application.update(application_params)
      render :show
    else
      render json: { errors: @application.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @application.destroy
    head :no_content
  end

  def launch
    additional_params = params.permit(:conversation_id, :contact_id, :inbox_id).to_h
    signed_url = generate_signed_url(@application, additional_params)

    @application.update(last_used_at: Time.current)

    render json: { url: signed_url }
  end

  def update_last_used
    @application.update(last_used_at: Time.current)
    render :show
  end

  private

  def set_application
    @application = Current.account.applications.find(params[:id])
  end

  def application_params
    params.require(:application).permit(
      :name, :url, :description, :status
    )
  end

  def generate_signed_url(application, additional_params = {})
    base_url = application.url

    # Parâmetros para a aplicação
    url_params = {
      user_id: Current.user.id,
      account_id: Current.account.id,
      email: Current.user.email,
      name: Current.user.name,
      locale: I18n.locale,
      timestamp: Time.current.to_i
    }.merge(additional_params)

    # Adicionar parâmetros à URL
    separator = base_url.include?('?') ? '&' : '?'
    "#{base_url}#{separator}#{url_params.to_query}"
  end

  def check_authorization
    authorize Current.account, :show?
  end
end
