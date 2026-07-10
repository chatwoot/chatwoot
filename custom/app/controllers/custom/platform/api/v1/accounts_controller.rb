# Merge-patch semantics for `custom_attributes` on the Platform API account
# update. Upstream assigns the param wholesale, so a sparse write like the
# control plane's periodic agentic-usage writeback
# (`custom_attributes: { agentic_ai_usage: N }` — docs/fork/ENTITLEMENTS.md)
# would REPLACE the whole jsonb and wipe Chatwoot-internal account state:
# `marked_for_deletion_at`/`_reason` (scheduled deletion), `plan_name`,
# `billing_currency`, onboarding attributes.
#
# RFC 7386-style: incoming keys overwrite, keys omitted from the patch survive,
# an explicit `null` deletes a key (and an explicit `{}` still clears all,
# unchanged from upstream). Create is untouched — there is nothing to merge
# into. `limits` keeps upstream's replace semantics on purpose: the control
# plane owns every limit key and always resends the complete set.
module Custom::Platform::Api::V1::AccountsController
  private

  def account_params
    permitted = super
    incoming = permitted[:custom_attributes]
    return permitted if @resource.blank? || incoming.blank?

    permitted.to_h.merge('custom_attributes' => merge_patched_custom_attributes(incoming.to_h))
  end

  def merge_patched_custom_attributes(incoming)
    deletions = incoming.select { |_key, value| value.nil? }.keys
    @resource.custom_attributes.to_h.merge(incoming).except(*deletions)
  end
end
