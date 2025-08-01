class WidgetLoaderController < ActionController::Base
  skip_forgery_protection

  def show
    shop = params[:shop]
    base_url = ENV['FRONTEND_URL']

    # Look up the token for this shop from the DB
    store = Dashassist::ShopifyStore.find_by(shop: shop)
    if store.nil?
      render plain: '// DashAssist: Store not found', status: :not_found, content_type: 'application/javascript'
      return
    end

    # Check if the store is enabled
    unless store.enabled?
      render plain: '// DashAssist: Store is not enabled', status: :forbidden, content_type: 'application/javascript'
      return
    end
    
    # Get the web widget channel for this inbox
    web_widget = store.inbox&.channel
    if web_widget.nil? || !web_widget.is_a?(Channel::WebWidget)
      render plain: '// DashAssist: Web widget not found', status: :not_found, content_type: 'application/javascript'
      return
    end
    
    token = web_widget.website_token || 'MISSING_TOKEN'

    js = <<~JAVASCRIPT
      (function() {
        var BASE_URL = "#{base_url}";
        var g = document.createElement('script'), s = document.getElementsByTagName('script')[0];
        g.src = BASE_URL + "/packs/js/sdk.js";
        g.defer = true;
        g.async = true;
        s.parentNode.insertBefore(g,s);
        g.onload = function() {
          window.dashassistSDK.run({
            websiteToken: '#{token}',
            baseUrl: BASE_URL,
            shopifyStore: true
          });
        }
      })();
    JAVASCRIPT

    response.headers['Content-Type'] = 'application/javascript'
    render plain: js
  end
end