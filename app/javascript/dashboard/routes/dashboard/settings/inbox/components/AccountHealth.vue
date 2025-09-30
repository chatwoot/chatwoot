<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const healthItems = computed(() => {
  if (!props.healthData) {
    return [];
  }

  return [
    {
      key: 'DISPLAY_PHONE_NUMBER',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.LABEL'),
      value: props.healthData.display_phone_number || 'N/A',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.TOOLTIP'
      ),
      show: true,
    },
    {
      key: 'VERIFIED_NAME',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.LABEL'),
      value: props.healthData.verified_name || 'N/A',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.TOOLTIP'),
      show: true,
    },
    {
      key: 'DISPLAY_NAME_STATUS',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.LABEL'),
      value: props.healthData.name_status || 'UNKNOWN',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.TOOLTIP'
      ),
      show: true,
      type: 'status',
    },
    {
      key: 'QUALITY_RATING',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.LABEL'),
      value: props.healthData.quality_rating || 'UNKNOWN',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.TOOLTIP'),
      show: true,
      type: 'quality',
    },
    {
      key: 'MESSAGING_LIMIT_TIER',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.LABEL'),
      value: props.healthData.messaging_limit_tier || 'UNKNOWN',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.TOOLTIP'
      ),
      show: true,
      type: 'tier',
    },
    {
      key: 'ACCOUNT_MODE',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.LABEL'),
      value: props.healthData.account_mode || 'UNKNOWN',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.TOOLTIP'),
      show: true,
      type: 'mode',
    },
  ];
});

const handleGoToSettings = () => {
  if (props.healthData?.business_id) {
    // WhatsApp Business Manager URL with specific business ID and phone numbers tab
    const whatsappBusinessUrl = `https://business.facebook.com/latest/whatsapp_manager/phone_numbers/?business_id=${props.healthData.business_id}&tab=phone-numbers`;
    window.open(whatsappBusinessUrl, '_blank');
  } else {
    // Fallback to general WhatsApp Business Manager if business_id is not available
    const fallbackUrl = 'https://business.facebook.com/';
    window.open(fallbackUrl, '_blank');
  }
};

const getQualityRatingTextColor = rating => {
  const colors = {
    GREEN: 'text-n-teal-11',
    YELLOW: 'text-n-yellow-11',
    RED: 'text-n-red-11',
    UNKNOWN: 'text-n-slate-12',
  };
  return colors[rating] || colors.UNKNOWN;
};

const formatTierDisplay = tier => {
  const tierMap = {
    TIER_250: '250 customers per 24h',
    TIER_1K: '1K customers per 24h',
    TIER_10K: '10K customers per 24h',
    TIER_100K: '100K customers per 24h',
    TIER_UNLIMITED: 'Unlimited customers per 24h',
  };
  return tierMap[tier] || tier;
};

const formatStatusDisplay = status => {
  const statusMap = {
    APPROVED: 'Approved',
    PENDING_REVIEW: 'Pending Review',
    AVAILABLE_WITHOUT_REVIEW: 'Available Without Review',
    REJECTED: 'Rejected',
  };
  return statusMap[status] || status;
};

const formatModeDisplay = mode => {
  const modeMap = {
    SANDBOX: 'Sandbox',
    LIVE: 'Live',
  };
  return modeMap[mode] || mode;
};

const getModeStatusTextColor = mode => {
  return mode === 'LIVE' ? 'text-n-teal-11' : 'text-n-slate-12';
};

const getStatusTextColor = status => {
  const colors = {
    APPROVED: 'text-n-teal-11',
    PENDING_REVIEW: 'text-n-yellow-11',
    AVAILABLE_WITHOUT_REVIEW: 'text-n-blue-11',
    REJECTED: 'text-n-red-11',
  };
  return colors[status] || 'text-n-slate-12';
};
</script>

<template>
  <div class="gap-4 pt-8 mx-8">
    <div
      class="px-5 py-5 space-y-5 rounded-xl border shadow-sm border-n-weak bg-n-solid-2"
    >
      <div class="grid grid-cols-[1fr_auto] gap-5">
        <div>
          <span class="text-base font-medium text-n-slate-12">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.TITLE') }}
          </span>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.DESCRIPTION') }}
          </p>
        </div>
        <ButtonV4 sm solid blue @click="handleGoToSettings">
          {{ t('INBOX_MGMT.ACCOUNT_HEALTH.GO_TO_SETTINGS') }}
        </ButtonV4>
      </div>

      <div v-if="props.healthData" class="pt-8 space-y-4">
        <div class="grid grid-cols-2 gap-6">
          <div
            v-for="item in healthItems"
            :key="item.key"
            class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
          >
            <div class="flex gap-2 items-center">
              <span class="text-sm font-medium text-n-slate-11">
                {{ item.label }}
              </span>
              <i
                v-tooltip.top="item.tooltip"
                class="flex-shrink-0 w-4 h-4 cursor-help i-lucide-info text-n-slate-9"
              />
            </div>
            <div class="flex items-center">
              <span
                v-if="item.type === 'quality'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getQualityRatingTextColor(item.value)"
              >
                {{ item.value }}
              </span>
              <span
                v-else-if="item.type === 'status'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getStatusTextColor(item.value)"
              >
                {{ formatStatusDisplay(item.value) }}
              </span>
              <span
                v-else-if="item.type === 'mode'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getModeStatusTextColor(item.value)"
              >
                {{ formatModeDisplay(item.value) }}
              </span>
              <span
                v-else-if="item.type === 'tier'"
                class="text-sm font-medium text-n-slate-12"
              >
                {{ formatTierDisplay(item.value) }}
              </span>
              <span v-else class="text-sm font-medium text-n-slate-12">{{
                item.value
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
