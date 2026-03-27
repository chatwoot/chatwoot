# frozen_string_literal: true

# Custom overlay — este arquivo NUNCA é sobrescrito por updates do Chatwoot upstream.
#
# Remove a validação de limite de licença Enterprise (pricing_plan_quantity).
# Nesta build todos os usuários têm acesso Enterprise sem restrição de quantidade.
#
# Mecanismo: o initializer 01_inject_enterprise_edition_module.rb chama
# User.include_mod_with('Concerns::User'), que busca (nessa ordem):
#   1. Enterprise::Concerns::User  (enterprise/app/models/enterprise/concerns/user.rb)
#   2. Custom::Concerns::User      (custom/app/models/custom/concerns/user.rb)  ← este arquivo
#
# O `skip_callback` remove o before_validation definido pelo módulo Enterprise.
module Custom::Concerns::User
  extend ActiveSupport::Concern

  included do
    # Remove o gate de licença adicionado por Enterprise::Concerns::User.
    # raise: false evita erro caso o callback já não exista (segurança defensiva).
    skip_callback :validation, :before, :ensure_installation_pricing_plan_quantity, raise: false
  end
end
