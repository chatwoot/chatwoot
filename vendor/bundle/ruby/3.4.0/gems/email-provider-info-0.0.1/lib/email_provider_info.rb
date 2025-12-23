# frozen_string_literal: true

module EmailProviderInfo
  require "email_provider_info/version"

  Value = Struct.new(:name, :url, :hosts)

  def self.providers
    @providers ||= JSON.parse(
      File.read(File.join(__dir__, "../data/providers.json")),
      symbolize_names: true
    )
  end

  def self.call(email)
    host = email.to_s.downcase.split("@").last

    info = providers.find {|provider| provider[:hosts].include?(host) }

    Value.new(info[:name], info[:url], info[:hosts]) if info
  end
end
