<script setup>
import { onActivated, onDeactivated, onMounted, ref } from 'vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useBranding } from 'shared/composables/useBranding';
import { LEGAL_COMPLIANCE_LINKS } from 'dashboard/constants/billing';

import BillingHeader from './BillingHeader.vue';
import ButtonV4 from 'next/button/Button.vue';

const { replaceInstallationName } = useBranding();
const { run, abort } = useAbortableRequest();

// Configured in Super Admin and served only to cloud administrators.
const dpaSigningUrl = ref('');
let needsRefresh = false;

const fetchLegalCompliance = async () => {
  try {
    await run(async signal => {
      const { data } = await EnterpriseAccountAPI.getLegalCompliance({
        signal,
      });
      if (!signal.aborted) dpaSigningUrl.value = data.dpa_signing_url || '';
    });
  } catch {
    // Keep the DPA row hidden when the link is unavailable.
    dpaSigningUrl.value = '';
  }
};

onMounted(fetchLegalCompliance);

onDeactivated(() => {
  needsRefresh = true;
  abort();
  dpaSigningUrl.value = '';
});

onActivated(() => {
  if (!needsRefresh) return;

  needsRefresh = false;
  fetchLegalCompliance();
});

const openExternalLink = url => {
  window.open(url, '_blank', 'noopener,noreferrer');
};
</script>

<template>
  <div
    class="rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-4 space-y-3"
  >
    <h3
      class="px-4 text-xs font-medium tracking-wider uppercase text-n-slate-10"
    >
      {{ $t('BILLING_SETTINGS.LEGAL_COMPLIANCE.TITLE') }}
    </h3>
    <div class="px-4 divide-y divide-n-weak">
      <BillingHeader
        v-if="dpaSigningUrl"
        class="py-3 first:pt-0 last:pb-0"
        :title="$t('BILLING_SETTINGS.LEGAL_COMPLIANCE.DPA.TITLE')"
        :description="
          replaceInstallationName(
            $t('BILLING_SETTINGS.LEGAL_COMPLIANCE.DPA.DESCRIPTION')
          )
        "
      >
        <ButtonV4 sm solid blue @click="openExternalLink(dpaSigningUrl)">
          {{ $t('BILLING_SETTINGS.LEGAL_COMPLIANCE.DPA.BUTTON_TXT') }}
        </ButtonV4>
      </BillingHeader>
      <BillingHeader
        class="py-3 first:pt-0 last:pb-0"
        :title="$t('BILLING_SETTINGS.LEGAL_COMPLIANCE.TRUST_CENTER.TITLE')"
        :description="
          $t('BILLING_SETTINGS.LEGAL_COMPLIANCE.TRUST_CENTER.DESCRIPTION')
        "
      >
        <ButtonV4
          sm
          faded
          slate
          @click="openExternalLink(LEGAL_COMPLIANCE_LINKS.TRUST_CENTER_URL)"
        >
          {{ $t('BILLING_SETTINGS.LEGAL_COMPLIANCE.TRUST_CENTER.BUTTON_TXT') }}
        </ButtonV4>
      </BillingHeader>
    </div>
  </div>
</template>
