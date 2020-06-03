class AppleAppController < ApplicationController
  def site_association
    site_association_json = render_to_string action: 'site_association', layout: false
    send_data site_association_json, filename: 'apple-app-site-association', type: 'application/json'
  end
end
