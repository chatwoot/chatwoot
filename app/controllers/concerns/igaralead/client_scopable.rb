module Igaralead
  module ClientScopable
    extend ActiveSupport::Concern

    included do
      before_action :validate_client_slug
    end

    private

    def validate_client_slug
      slug = params[:client_slug]
      return if slug.blank?

      account = Current.account
      return if account&.hub_client_slug == slug

      render json: { error: 'Acesso negado: cliente inválido' }, status: :forbidden
    end
  end
end
