class Api::V1::Accounts::Integrations::SocialwiseChatwitController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def create
    # Verificar se já existe um hook do Socialwise
    existing_hook = Current.account.hooks.find_by(app_id: 'socialwise_chatwit')
    
    if existing_hook
      # Atualizar hook existente
      existing_hook.update!(
        status: 'enabled',
        settings: { 'enabled' => true }
      )
      @hook = existing_hook
    else
      # Criar novo hook
      @hook = Current.account.hooks.create!(
        app_id: 'socialwise_chatwit',
        status: 'enabled',
        hook_type: 'account',
        settings: { 'enabled' => true }
      )
    end

    render json: {
      message: 'Socialwise Chatwit configurado com sucesso!',
      hook: @hook
    }
  end

  def update
    hook = Current.account.hooks.find_by(app_id: 'socialwise_chatwit')
    
    if hook
      hook.update!(permitted_params.slice(:status, :settings))
      render json: {
        message: 'Configurações do Socialwise Chatwit atualizadas!',
        hook: hook
      }
    else
      render json: { error: 'Hook do Socialwise não encontrado' }, status: :not_found
    end
  end

  def destroy
    hook = Current.account.hooks.find_by(app_id: 'socialwise_chatwit')
    
    if hook
      hook.destroy!
      render json: { message: 'Socialwise Chatwit desativado com sucesso!' }
    else
      render json: { error: 'Hook do Socialwise não encontrado' }, status: :not_found
    end
  end

  private

  def permitted_params
    params.require(:hook).permit(:status, settings: {})
  end
end 