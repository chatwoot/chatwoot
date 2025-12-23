# frozen_string_literal: true

module WebConsole
  class Request < ActionDispatch::Request
    cattr_accessor :permissions, default: Permissions.new

    def permitted?
      permissions.include?(strict_remote_ip)
    end

    def strict_remote_ip
      GetSecureIp.new(self, permissions).to_s
    rescue ActionDispatch::RemoteIp::IpSpoofAttackError
      "[Spoofed]"
    end

    private

      class GetSecureIp < ActionDispatch::RemoteIp::GetIp
        def initialize(req, proxies)
          # After rails/rails@07b2ff0 ActionDispatch::RemoteIp::GetIp initializes
          # with a ActionDispatch::Request object instead of plain Rack
          # environment hash. Keep both @req and @env here, so we don't if/else
          # on Rails versions.
          @req      = req
          @env      = req.env
          @check_ip = true
          @proxies  = proxies
        end

        def filter_proxies(ips)
          ips.reject do |ip|
            @proxies.include?(ip)
          end
        end
      end
  end
end
