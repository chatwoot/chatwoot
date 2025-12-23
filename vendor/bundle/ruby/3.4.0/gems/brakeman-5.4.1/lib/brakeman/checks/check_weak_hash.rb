require 'brakeman/checks/base_check'

class Brakeman::CheckWeakHash < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Checks for use of weak hashes like MD5"

  DIGEST_CALLS = [:base64digest, :digest, :hexdigest, :new]

  def run_check
    tracker.find_call(:targets => [:'Digest::MD5', :'Digest::SHA1', :'OpenSSL::Digest::MD5', :'OpenSSL::Digest::SHA1'], :nested => true).each do |result|
      process_hash_result result
    end

    tracker.find_call(:target => :'Digest::HMAC', :methods => [:new, :hexdigest], :nested => true).each do |result|
      process_hmac_result result
    end

    tracker.find_call(:targets => [:'OpenSSL::Digest::Digest', :'OpenSSL::Digest'], :method => :new).each do |result|
      process_openssl_result result
    end
  end

  def process_hash_result result
    return unless original? result

    input = nil
    call = result[:call]

    if DIGEST_CALLS.include? call.method
      if input = user_input_as_arg?(call)
        confidence = :high
      elsif input = hashing_password?(call)
        confidence = :high
      else
        confidence = :medium
      end
    else
      confidence = :medium
    end

    message = msg("Weak hashing algorithm used")

    case call.target.last
    when :MD5
      message << ": " << msg_lit("MD5")
    when :SHA1
      message << ": " << msg_lit("SHA1")
    end

    warn :result => result,
      :warning_type => "Weak Hash",
      :warning_code => :weak_hash_digest,
      :message => message,
      :confidence => confidence,
      :user_input => input,
      :cwe_id => [328]
  end

  def process_hmac_result result
    return unless original? result

    call = result[:call]

    message = msg("Weak hashing algorithm used in HMAC")

    case call.third_arg.last
    when :MD5
      message << ": " << msg_lit("MD5")
    when :SHA1
      message << ": " << msg_lit("SHA1")
    end

    warn :result => result,
      :warning_type => "Weak Hash",
      :warning_code => :weak_hash_hmac,
      :message => message,
      :confidence => :medium,
      :cwe_id => [328]
  end

  def process_openssl_result result
    return unless original? result

    arg = result[:call].first_arg

    if string? arg
      alg = arg.value.upcase

      if alg == 'MD5' or alg == 'SHA1'
        warn :result => result,
          :warning_type => "Weak Hash",
          :warning_code => :weak_hash_digest,
          :message => msg("Weak hashing algorithm used: ", msg_lit(alg)),
          :confidence => :medium,
          :cwe_id => [328]
      end
    end
  end

  def user_input_as_arg? call
    call.each_arg do |arg|
      if input = include_user_input?(arg)
        return input
      end
    end

    nil
  end

  def hashing_password? call
    call.each_arg do |arg|
      @has_password = false

      process arg

      if @has_password
        return @has_password
      end
    end

    nil
  end

  def process_call exp
    if exp.method == :password
      @has_password = exp
    else
      process_default exp
    end

    exp
  end

  def process_ivar exp
    if exp.value == :@password
      @has_password = exp
    end

    exp
  end

  def process_lvar exp
    if exp.value == :password
      @has_password = exp
    end

    exp
  end
end
