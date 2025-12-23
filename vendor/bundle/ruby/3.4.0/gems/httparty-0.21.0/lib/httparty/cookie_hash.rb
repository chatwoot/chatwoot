# frozen_string_literal: true

class HTTParty::CookieHash < Hash #:nodoc:
  CLIENT_COOKIES = %w(path expires domain path secure httponly samesite)

  def add_cookies(data)
    case data
    when Hash
      merge!(data)
    when String
      data.split('; ').each do |cookie|
        key, value = cookie.split('=', 2)
        self[key.to_sym] = value if key
      end
    else
      raise "add_cookies only takes a Hash or a String"
    end
  end

  def to_cookie_string
    select { |k, v| !CLIENT_COOKIES.include?(k.to_s.downcase) }.collect { |k, v| "#{k}=#{v}" }.join('; ')
  end
end
