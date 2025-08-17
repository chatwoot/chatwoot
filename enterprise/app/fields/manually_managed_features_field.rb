require 'administrate/field/base'

# This field is used in the super admin panel to allow administrators
# to manually grant specific features to accounts, overriding their billing plan restrictions.
class ManuallyManagedFeaturesField < Administrate::Field::Base
  include BillingPlans

  def data
    Internal::Accounts::InternalAttributesService.new(resource).manually_managed_features
  end

  def to_s
    data.is_a?(Array) ? data.join(', ') : '[]'
  end

  def all_features
    self.class.all_features
  end

  def selected_features
    # If we have direct array data, use it (for rendering after form submission)
    return data if data.is_a?(Array)

    # Otherwise, use the service to retrieve the data from internal_attributes
    if resource.respond_to?(:internal_attributes)
      service = Internal::Accounts::InternalAttributesService.new(resource)
      return service.manually_managed_features
    end

    # Fallback to empty array if no data available
    []
  end
end
