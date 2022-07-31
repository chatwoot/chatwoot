class Webhooks::ShopifyController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
    skip_before_action :set_current_user

    def callback
        code = params[:code]
        account_name = params[:shop]
        
        shopify_account = Integrations::Shopify.find_by account_name: account_name
    
        url = 'https://'+shopify_account.account_name+'/admin/oauth/access_token';
        response = RestClient.post(url,  {client_id: shopify_account.api_key, client_secret: shopify_account.api_secret, code: code})
    
        shopify_account.access_token = JSON.parse(response)['access_token']
        shopify_account.save!

        redirect_to '/app/accounts/1/settings/integrations/shopify'
    end     
end
  