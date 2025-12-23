require 'brakeman/checks/base_check'

class Brakeman::CheckWeakRSAKey < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for weak uses RSA keys"

  def run_check
    check_rsa_key_creation
    check_rsa_operations
  end

  def check_rsa_key_creation
    tracker.find_call(targets: [:'OpenSSL::PKey::RSA'], method: [:new, :generate], nested: true).each do |result|
      key_size_arg = result[:call].first_arg
      check_key_size(result, key_size_arg)
    end

    tracker.find_call(targets: [:'OpenSSL::PKey'], method: [:generate_key], nested: true).each do |result|
      call = result[:call]
      key_type = call.first_arg
      options_arg = call.second_arg

      next unless options_arg and hash? options_arg

      if string? key_type and key_type.value.upcase == 'RSA'
        key_size_arg = (hash_access(options_arg, :rsa_keygen_bits) || hash_access(options_arg, s(:str, 'rsa_key_gen_bits')))
        check_key_size(result, key_size_arg)
      end
    end
  end

  def check_rsa_operations
    tracker.find_call(targets: [:'OpenSSL::PKey::RSA.new'], methods: [:public_encrypt, :public_decrypt, :private_encrypt, :private_decrypt], nested: true).each do |result|
      padding_arg = result[:call].second_arg
      check_padding(result, padding_arg)
    end

    tracker.find_call(targets: [:'OpenSSL::PKey.generate_key'], methods: [:encrypt, :decrypt, :sign, :verify, :sign_raw, :verify_raw], nested: true).each do |result|
      call = result[:call]
      options_arg = call.last_arg

      if options_arg and hash? options_arg
        padding_arg = (hash_access(options_arg, :rsa_padding_mode) || hash_access(options_arg, s(:str, 'rsa_padding_mode')))
      else
        padding_arg = nil
      end

      check_padding(result, padding_arg)
    end
  end

  def check_key_size result, key_size_arg
    return unless number? key_size_arg
    return unless original? result

    key_size = key_size_arg.value

    if key_size < 1024
      confidence = :high
      message = msg("RSA key with size ", msg_code(key_size.to_s), " is considered very weak. Use at least 2048 bit key size")
    elsif key_size < 2048
      confidence = :medium
      message = msg("RSA key with size ", msg_code(key_size.to_s), " is considered weak. Use at least 2048 bit key size")
    else
      return
    end

    warn result: result,
      warning_type: "Weak Cryptography",
      warning_code: :small_rsa_key_size,
      message: message,
      confidence: confidence,
      user_input: key_size_arg,
      cwe_id: [326]
  end

  PKCS1_PADDING = s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :PKCS1_PADDING).freeze
  PKCS1_PADDING_STR = s(:str, 'pkcs1').freeze
  SSLV23_PADDING = s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :SSLV23_PADDING).freeze
  SSLV23_PADDING_STR = s(:str, 'sslv23').freeze
  NO_PADDING = s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING).freeze
  NO_PADDING_STR = s(:str, 'none').freeze

  def check_padding result, padding_arg
    return unless original? result

    if string? padding_arg
      padding_arg = padding_arg.deep_clone(padding_arg.line)
      padding_arg.value.downcase!
    end

    case padding_arg
    when PKCS1_PADDING, PKCS1_PADDING_STR, nil
      message = "Use of padding mode PKCS1 (default if not specified), which is known to be insecure. Use OAEP instead"
    when SSLV23_PADDING, SSLV23_PADDING_STR
      message = "Use of padding mode SSLV23 for RSA key, which is only useful for outdated versions of SSL. Use OAEP instead"
    when NO_PADDING, NO_PADDING_STR
      message = "No padding mode used for RSA key. A safe padding mode (OAEP) should be specified for RSA keys"
    else
      return
    end

    warn result: result,
      warning_type: "Weak Cryptography",
      warning_code: :insecure_rsa_padding_mode,
      message: message,
      confidence: :high,
      user_input: padding_arg,
      cwe_id: [780]
  end
end
