require 'brakeman/checks/base_check'

# Author: Paul Deardorff (themetric)
# Checks models to see if important foreign keys
# or attributes are exposed as attr_accessible when
# they probably shouldn't be.

class Brakeman::CheckModelAttrAccessible < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Reports models which have dangerous attributes defined via attr_accessible"

  SUSP_ATTRS = [
    [:admin, :high], # Very dangerous unless some Rails authorization used
    [:role, :medium],
    [:banned, :medium],
    [:account_id, :high],
    [/\S*_id(s?)\z/, :weak] # All other foreign keys have weak/low confidence
  ]

  def run_check
    check_models do |name, model|
      model.attr_accessible.each do |attribute|
        next if role_limited? model, attribute

        SUSP_ATTRS.each do |susp_attr, confidence|
          if susp_attr.is_a?(Regexp) and susp_attr =~ attribute.to_s or susp_attr == attribute
            warn :model => model,
              :file => model.file,
              :warning_type => "Mass Assignment",
              :warning_code => :dangerous_attr_accessible,
              :message => "Potentially dangerous attribute available for mass assignment",
              :confidence => confidence,
              :code => Sexp.new(:lit, attribute),
              :cwe_id => [915]
            break # Prevent from matching single attr multiple times
          end
        end
      end
    end
  end

  def role_limited? model, attribute
    role_accessible = model.role_accessible
    return if role_accessible.nil?
    role_accessible.include? attribute
  end

  def check_models
    tracker.models.each do |name, model|
      if !model.attr_accessible.nil?
        yield name, model
      end
    end
  end
end
