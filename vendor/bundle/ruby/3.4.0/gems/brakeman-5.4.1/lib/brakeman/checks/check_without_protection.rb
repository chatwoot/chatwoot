require 'brakeman/checks/base_check'

#Check for bypassing mass assignment protection
#with without_protection => true
#
#Only for Rails 3.1
class Brakeman::CheckWithoutProtection < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for mass assignment using without_protection"

  def run_check
    if version_between? "0.0.0", "3.0.99"
      return
    end

    return if active_record_models.empty?

    Brakeman.debug "Finding all mass assignments"
    calls = tracker.find_call :targets => active_record_models.keys, :methods => [:new,
      :attributes=, 
      :update_attributes, 
      :update_attributes!,
      :create,
      :create!]

    Brakeman.debug "Processing all mass assignments"
    calls.each do |result|
      process_result result
    end
  end

  #All results should be Model.new(...) or Model.attributes=() calls
  def process_result res
    call = res[:call]
    last_arg = call.last_arg

    if hash? last_arg and not call.original_line and not duplicate? res

      if value = hash_access(last_arg, :without_protection)
        if true? value
          add_result res

          if input = include_user_input?(call.arglist)
            confidence = :high
          elsif all_literals? call
            return
          else
            confidence = :medium
          end

          warn :result => res, 
            :warning_type => "Mass Assignment", 
            :warning_code => :mass_assign_without_protection,
            :message => "Unprotected mass assignment",
            :code => call, 
            :user_input => input,
            :confidence => confidence,
            :cwe_id => [915]

        end
      end
    end
  end

  def all_literals? call
    call.each_arg do |arg|
      if hash? arg
        hash_iterate arg do |k, v|
          unless node_type? k, :str, :lit, :false, :true and node_type? v, :str, :lit, :false, :true
            return false
          end
        end
      else
        return false
      end
    end

    true
  end
end
