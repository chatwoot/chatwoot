require 'brakeman/checks/base_check'

# Checks if verify_mode= is called with OpenSSL::SSL::VERIFY_NONE

class Brakeman::CheckSSLVerify < Brakeman::BaseCheck
  Brakeman::Checks.add self

  SSL_VERIFY_NONE = s(:colon2, s(:colon2, s(:const, :OpenSSL), :SSL), :VERIFY_NONE)

  @description = "Checks for OpenSSL::SSL::VERIFY_NONE"

  def run_check
    check_open_ssl_verify_none
    check_http_start
  end

  def check_open_ssl_verify_none
    tracker.find_call(:method => :verify_mode=).each {|call| process_verify_mode_result(call) }
  end

  def process_verify_mode_result result
    if result[:call].last_arg == SSL_VERIFY_NONE
      warn_about_ssl_verification_bypass result
    end
  end

  def check_http_start
    tracker.find_call(:target => :'Net::HTTP', :method => :start).each { |call| process_http_start_result call }
  end

  def process_http_start_result result
    arg = result[:call].last_arg

    if hash? arg and hash_access(arg, :verify_mode) == SSL_VERIFY_NONE
      warn_about_ssl_verification_bypass result
    end
  end

  def warn_about_ssl_verification_bypass result
    return unless original? result

    warn :result => result,
      :warning_type => "SSL Verification Bypass",
      :warning_code => :ssl_verification_bypass,
      :message => "SSL certificate verification was bypassed",
      :confidence => :high,
      :cwe_id => [295]
  end
end
