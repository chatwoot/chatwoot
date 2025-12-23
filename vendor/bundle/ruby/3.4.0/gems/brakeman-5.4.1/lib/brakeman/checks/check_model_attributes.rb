require 'brakeman/checks/base_check'

#Check if mass assignment is used with models
#which inherit from ActiveRecord::Base.
class Brakeman::CheckModelAttributes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Reports models which do not use attr_restricted and warns on models that use attr_protected"

  def run_check
    return if mass_assign_disabled? or tracker.config.has_gem?(:protected_attributes)

    #Roll warnings into one warning for all models
    if tracker.options[:collapse_mass_assignment]
      Brakeman.notify "[Notice] The `collapse_mass_assignment` option has been removed."
    end

    check_models do |name, model|
      if model.attr_protected.nil?
        warn :model => model,
          :file => model.file,
          :line => model.top_line,
          :warning_type => "Attribute Restriction",
          :warning_code => :no_attr_accessible,
          :message => msg("Mass assignment is not restricted using ", msg_code("attr_accessible")),
          :confidence => :high,
          :cwe_id => [915] # TODO: Should this be mass assignment?
      elsif not tracker.options[:ignore_attr_protected]
        message, confidence, link = check_for_attr_protected_bypass

        if link
          warning_code = :CVE_2013_0276
        else
          warning_code = :attr_protected_used
        end

        warn :model => model,
          :file => model.file,
          :line => model.attr_protected.first.line,
          :warning_type => "Attribute Restriction",
          :warning_code => warning_code,
          :message => message,
          :confidence => confidence,
          :cwe_id => [915] # TODO: Should this be mass assignment?
      end
    end
  end

  def check_models
    tracker.models.each do |name, model|
      if model.unprotected_model?
        yield name, model
      end
    end
  end

  def check_for_attr_protected_bypass
    upgrade_version = case
                      when version_between?("2.0.0", "2.3.16")
                        "2.3.17"
                      when version_between?("3.0.0", "3.0.99")
                        "3.2.11"
                      when version_between?("3.1.0", "3.1.10")
                        "3.1.11"
                      when version_between?("3.2.0", "3.2.11")
                        "3.2.12"
                      else
                        nil
                      end

    if upgrade_version
      message = msg(msg_code("attr_protected"), " is bypassable in ", msg_version(rails_version), ". Use ", msg_code("attr_accessible"), " or upgrade to ", msg_version(upgrade_version))
      confidence = :high
      link = "https://groups.google.com/d/topic/rubyonrails-security/AFBKNY7VSH8/discussion"
    else
      message = msg(msg_code("attr_accessible"), " is recommended over ", msg_code("attr_protected"))
      confidence = :medium
      link = nil
    end

    return message, confidence, link
  end
end
