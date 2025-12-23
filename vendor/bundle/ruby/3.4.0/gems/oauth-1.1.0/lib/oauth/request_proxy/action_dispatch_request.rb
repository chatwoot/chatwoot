# frozen_string_literal: true

require "oauth/request_proxy/rack_request"

module OAuth
  module RequestProxy
    class ActionDispatchRequest < OAuth::RequestProxy::RackRequest
      proxies ::ActionDispatch::Request
    end
  end
end
