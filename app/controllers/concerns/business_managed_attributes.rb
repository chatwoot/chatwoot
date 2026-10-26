# Customers set contact attributes through the widget and the public API.
# Business managed attributes change only through the account API and the dashboard, so these requests drop them.
module BusinessManagedAttributes
  private

  def without_business_managed_attributes(account, contact_params)
    return contact_params if contact_params[:custom_attributes].blank?

    contact_params.merge(custom_attributes: contact_params[:custom_attributes].except(*business_managed_attribute_keys(account)))
  end

  def business_managed_attribute_keys(account)
    account.custom_attribute_definitions.business_managed.pluck(:attribute_key)
  end
end
