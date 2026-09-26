class Public::Api::V1::SitemapsController < PublicController
  def index
    @portals = Portal.active
    @base_url = ChatwootApp.help_center_root.to_s
    @base_url = "https://#{@base_url}" unless @base_url.include?('://')
  end
end
