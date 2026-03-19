module Enterprise::Whatsapp::Providers::WhatsappCloudService
  extend ActiveSupport::Concern

  included do
    include ::Whatsapp::Providers::WhatsappCloudCallMethods
  end
end
