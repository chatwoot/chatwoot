# Whether an address points inside this deployment.
#
# What it answers decides two things: whether an inbox may be pointed at it at all, and
# whether outbound media is offered at the public URL or at INTERNAL_HOST_URL. Both are
# asked while saving or while building a URL, so nothing here resolves a name: that is a
# network call, and the calls themselves are filtered when they are made.
module Whatsapp::Session::PrivateAddress
  class << self
    def url?(value)
      uri = URI.parse(value.to_s)
      uri.is_a?(URI::HTTP) && host?(uri.host.to_s)
    rescue URI::InvalidURIError
      false
    end

    def http_url?(value)
      uri = URI.parse(value.to_s)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    def host?(host)
      host = host.delete_prefix('[').delete_suffix(']').delete_suffix('.').downcase
      return false if host.blank?

      # An address answers to the address rules only. Asking the name rules about one
      # would call every IPv6 literal private, since it has no dot in it.
      address = ip(host)
      address ? private_address?(address) : private_name?(host)
    end

    private

    def ip(host)
      IPAddr.new(host)
    rescue IPAddr::Error
      nil
    end

    def private_address?(address)
      address.loopback? || address.private? || address.link_local? || address.to_s == '0.0.0.0'
    end

    # The trailing dot stripped above is the root label, so `localhost.` is still
    # localhost. A name with no dot at all cannot be public either, and is how a service
    # next door is addressed on a compose network.
    def private_name?(host)
      host == 'localhost' || host.end_with?('.localhost') || host.exclude?('.')
    end
  end
end
