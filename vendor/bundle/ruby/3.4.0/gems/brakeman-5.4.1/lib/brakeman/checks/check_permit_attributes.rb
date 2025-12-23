require 'brakeman/checks/base_check'

class Brakeman::CheckPermitAttributes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Warn on potentially dangerous attributes allowed via permit"

  SUSPICIOUS_KEYS = {
    admin: :high,
    account_id: :high,
    role: :medium,
    banned: :medium,
  }

  def run_check
    tracker.find_call(:method => :permit).each do |result|
      check_permit result
    end
  end

  def check_permit result
    return unless original? result

    call = result[:call]

    call.each_arg do |arg|
      if symbol? arg
        if SUSPICIOUS_KEYS.key? arg.value
          warn_on_permit_key result, arg
        end
      end
    end
  end

  def warn_on_permit_key result, key, confidence = nil
    warn :result => result,
      :warning_type => "Mass Assignment",
      :warning_code => :dangerous_permit_key,
      :message => "Potentially dangerous key allowed for mass assignment",
      :confidence => (confidence || SUSPICIOUS_KEYS[key.value]),
      :user_input => key,
      :cwe_id => [915]
  end
end
