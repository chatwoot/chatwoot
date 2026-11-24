class Api::V1::Accounts::Companies::EnrichmentsController < Api::V1::Accounts::Companies::BaseController
  before_action :ensure_enrichment_enabled!
  before_action -> { authorize(@company, :enrich?) }
  before_action :validate_enrichment_request

  def create
    return render 'api/v1/accounts/companies/show' if Companies::EnrichmentService.new(@company, overwrite: true).perform

    render json: { error: I18n.t('errors.companies.enrichment.not_found') }, status: :unprocessable_entity
  end

  private

  def ensure_enrichment_enabled!
    return if Current.account.feature_enabled?('company_enrichment')

    render json: { error: I18n.t('errors.companies.enrichment.plan_required') }, status: :forbidden
  end

  def validate_enrichment_request
    error = if !Companies::EnrichmentService.enabled?
              'errors.companies.enrichment.not_configured'
            elsif @company.domain.blank?
              'errors.companies.enrichment.domain_missing'
            end
    render json: { error: I18n.t(error) }, status: :unprocessable_entity if error
  end
end
