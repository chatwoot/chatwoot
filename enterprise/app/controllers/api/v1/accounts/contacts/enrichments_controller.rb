class Api::V1::Accounts::Contacts::EnrichmentsController < Api::V1::Accounts::Contacts::BaseController
  before_action :ensure_enrichment_enabled!
  before_action -> { authorize(@contact, :enrich?) }
  before_action :validate_enrichment_request

  def create
    @contact = @enrichment_service.perform
    return render 'api/v1/accounts/contacts/show' if @contact

    render json: { error: I18n.t('errors.contacts.enrichment.not_found') }, status: :unprocessable_entity
  end

  private

  # Contact enrichment ships with the same plans as company enrichment.
  def ensure_enrichment_enabled!
    return if Current.account.feature_enabled?('company_enrichment')

    render json: { error: I18n.t('errors.contacts.enrichment.plan_required') }, status: :forbidden
  end

  def validate_enrichment_request
    @enrichment_service = Contacts::EnrichmentService.new(@contact, overwrite: true)
    error = if !Contacts::EnrichmentService.enabled?
              'errors.contacts.enrichment.not_configured'
            elsif @enrichment_service.identity_clues.blank?
              'errors.contacts.enrichment.details_missing'
            end
    render json: { error: I18n.t(error) }, status: :unprocessable_entity if error
  end
end
