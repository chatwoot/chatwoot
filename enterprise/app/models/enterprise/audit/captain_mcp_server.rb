module Enterprise::Audit::CaptainMcpServer
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account, except: [:auth_config]
  end
end
