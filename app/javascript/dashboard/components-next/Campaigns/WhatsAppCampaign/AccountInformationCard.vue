<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
});

const MODE_COLORS = {
  LIVE: 'bg-n-teal-11',
  SANDBOX: 'bg-n-slate-11',
};

const QUALITY_COLORS = {
  GREEN: 'bg-n-teal-11',
  YELLOW: 'bg-n-amber-11',
  RED: 'bg-n-ruby-11',
};

const { t, te } = useI18n();

const translateValue = (namespace, value) => {
  const key = `INBOX_MGMT.ACCOUNT_HEALTH.VALUES.${namespace}.${value}`;
  return te(key)
    ? t(key)
    : t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.UNAVAILABLE');
};

const rows = computed(() => {
  const {
    messaging_limit_tier: tier,
    account_mode: mode,
    quality_rating: quality,
  } = props.healthData;

  return [
    {
      key: 'tier',
      label: t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.MESSAGING_TIER'),
      description: translateValue('TIERS', tier),
      value: translateValue('TIER_NAMES', tier),
    },
    {
      key: 'status',
      label: t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.ACCOUNT_STATUS'),
      description: t(
        'CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.STATUS_DESCRIPTION'
      ),
      value: translateValue('MODES', mode),
      dotClass: MODE_COLORS[mode],
    },
    {
      key: 'health',
      label: t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.ACCOUNT_HEALTH'),
      description: t(
        'CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.HEALTH_DESCRIPTION'
      ),
      value: translateValue('QUALITY', quality),
      dotClass: QUALITY_COLORS[quality],
    },
  ];
});

const managerUrl = computed(() => {
  const { business_portfolio_id: portfolioId, business_account_id: accountId } =
    props.healthData;

  if (!portfolioId || !accountId) return 'https://business.facebook.com/';

  const url = new URL(
    'https://business.facebook.com/latest/whatsapp_manager/phone_numbers/'
  );
  url.searchParams.set('business_id', portfolioId);
  url.searchParams.set('asset_id', accountId);
  return url.toString();
});

const openManager = () => window.open(managerUrl.value, '_blank');
</script>

<template>
  <section
    class="flex flex-col w-full gap-5 p-4 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
  >
    <h2 class="text-heading-2 text-n-slate-12">
      {{ t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.TITLE') }}
    </h2>
    <div v-if="healthData" class="flex flex-col divide-y divide-n-weak">
      <div
        v-for="row in rows"
        :key="row.key"
        class="flex flex-col gap-2 py-3 first:pt-0 last:pb-0"
      >
        <div class="flex items-center justify-between gap-3">
          <span class="text-heading-3 text-n-slate-12">{{ row.label }}</span>
          <Button
            v-tooltip.top="t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.OPEN')"
            variant="ghost"
            color="slate"
            size="xs"
            icon="i-lucide-arrow-up-right"
            @click="openManager"
          />
        </div>
        <div class="flex items-center justify-between gap-3">
          <span class="min-w-0 truncate text-body-main text-n-slate-11">
            {{ row.description }}
          </span>
          <div class="flex items-center gap-1.5 shrink-0">
            <span
              v-if="row.dotClass"
              class="rounded-full size-1.5"
              :class="row.dotClass"
            />
            <span class="text-body-main text-n-slate-12">{{ row.value }}</span>
          </div>
        </div>
      </div>
    </div>
    <p v-else class="mb-0 text-body-main text-n-slate-11">
      {{ t('CAMPAIGN.WHATSAPP.FORM.ACCOUNT_INFORMATION.EMPTY_STATE') }}
    </p>
  </section>
</template>
