# Controller-level quota rejection with the shared 402 contract
# (docs/fork/ENTITLEMENTS.md). Extends the upstream 402 `{ error: }` shape
# additively — never change or remove the existing keys.
module Custom::Concerns::QuotaEnforcement
  private

  def check_quota(resource)
    result = Custom::EntitlementService.new(Current.account).check(resource)
    return if result.allowed?

    render json: {
      error: I18n.t('errors.quota.exceeded',
                    resource: result.resource.to_s.humanize.downcase,
                    current: result.current,
                    limit: result.limit),
      error_code: 'quota_exceeded',
      resource: result.resource,
      current: result.current,
      limit: result.limit
    }, status: :payment_required
  end
end
