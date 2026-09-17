module Enterprise::Api::V1::Accounts::ContactsController
  private

  def contact_search_candidates(scope)
    ::SearchIndexing::Search.new(account: Current.account, entity: 'contacts', query: params[:q].strip,
                                 case_sensitive_identifier: true).narrow(scope)
  end

  def permitted_params
    params_with_company_id = super
    return params_with_company_id unless Current.account.feature_enabled?('companies')
    return params_with_company_id unless params.key?(:company_id)

    params_with_company_id.merge(company_id: permitted_company_id)
  end

  def permitted_company_id
    return nil if params[:company_id].blank?

    Current.account.companies.find(params[:company_id]).id
  end
end
