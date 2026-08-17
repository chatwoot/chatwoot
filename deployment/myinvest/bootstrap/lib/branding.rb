# frozen_string_literal: true

module Myinvest; end

class Myinvest::Branding
  CONFIG = {
    'INSTALLATION_NAME' => 'MyInvest Support',
    'BRAND_NAME' => 'MyInvest Support',
    'BRAND_URL' => 'https://www.myinvest-pro.de',
    'WIDGET_BRAND_URL' => 'https://www.myinvest-pro.de',
    'TERMS_URL' => 'https://www.myinvest-pro.de/agb',
    'PRIVACY_URL' => 'https://www.myinvest-pro.de/datenschutz',
    'LOGO' => '/brand-assets/logo.svg?v=myinvest-support-20260817',
    'LOGO_DARK' => '/brand-assets/logo_dark.svg?v=myinvest-support-20260817',
    'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.png?v=myinvest-support-20260817',
    'DISPLAY_MANIFEST' => false
  }.freeze

  def self.apply!
    ActiveRecord::Base.transaction do
      CONFIG.each do |name, value|
        config = InstallationConfig.find_or_initialize_by(name: name)
        next if config.value == value && config.locked?

        config.value = value
        config.locked = true
        config.save!
      end
    end

    CONFIG
  end
end
