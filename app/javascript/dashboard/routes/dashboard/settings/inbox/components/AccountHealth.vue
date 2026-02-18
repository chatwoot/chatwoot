<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import ButtonV4 from 'next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const QUALITY_COLORS = {
  GREEN: 'text-n-teal-11',
  YELLOW: 'text-n-amber-11',
  RED: 'text-n-ruby-11',
  UNKNOWN: 'text-n-slate-12',
};

const STATUS_COLORS = {
  APPROVED: 'text-n-teal-11',
  PENDING_REVIEW: 'text-n-amber-11',
  AVAILABLE_WITHOUT_REVIEW: 'text-n-teal-11',
  REJECTED: 'text-n-ruby-9',
  DECLINED: 'text-n-ruby-9',
};

const MODE_COLORS = {
  LIVE: 'text-n-teal-11',
  SANDBOX: 'text-n-slate-11',
};

const healthItems = computed(() => {
  if (!props.healthData) {
    return [];
  }

  const {
    display_phone_number: displayPhoneNumber,
    verified_name: verifiedName,
    name_status: nameStatus,
    quality_rating: qualityRating,
    messaging_limit_tier: messagingLimitTier,
    account_mode: accountMode,
  } = props.healthData;

  return [
    {
      key: 'displayPhoneNumber',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.LABEL'),
      value: displayPhoneNumber || 'N/A',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.TOOLTIP'
      ),
      show: true,
    },
    {
      key: 'verifiedName',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.LABEL'),
      value: verifiedName || 'N/A',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.TOOLTIP'),
      show: true,
    },
    {
      key: 'displayNameStatus',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.LABEL'),
      value: nameStatus || 'UNKNOWN',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.TOOLTIP'
      ),
      show: true,
      type: 'status',
    },
    {
      key: 'qualityRating',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.LABEL'),
      value: qualityRating || 'UNKNOWN',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.TOOLTIP'),
      show: true,
      type: 'quality',
    },
    {
      key: 'messagingLimitTier',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.LABEL'),
      value: messagingLimitTier || 'UNKNOWN',
      tooltip: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.TOOLTIP'
      ),
      show: true,
      type: 'tier',
    },
    {
      key: 'accountMode',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.LABEL'),
      value: accountMode || 'UNKNOWN',
      tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.TOOLTIP'),
      show: true,
      type: 'mode',
    },
  ];
});

const handleGoToSettings = () => {
  const { business_id: businessId } = props.healthData || {};

  if (businessId) {
    // WhatsApp Business Manager URL with specific business ID and phone numbers tab
    const whatsappBusinessUrl = `https://business.facebook.com/latest/whatsapp_manager/phone_numbers/?business_id=${businessId}&tab=phone-numbers`;
    window.open(whatsappBusinessUrl, '_blank');
  } else {
    // Fallback to general WhatsApp Business Manager if business_id is not available
    const fallbackUrl = 'https://business.facebook.com/';
    window.open(fallbackUrl, '_blank');
  }
};

const getQualityRatingTextColor = rating =>
  QUALITY_COLORS[rating] || QUALITY_COLORS.UNKNOWN;

const formatTierDisplay = tier =>
  t(`INBOX_MGMT.ACCOUNT_HEALTH.VALUES.TIERS.${tier}`) || tier;

const formatStatusDisplay = status =>
  t(`INBOX_MGMT.ACCOUNT_HEALTH.VALUES.STATUSES.${status}`) || status;

const formatModeDisplay = mode =>
  t(`INBOX_MGMT.ACCOUNT_HEALTH.VALUES.MODES.${mode}`) || mode;

const getModeStatusTextColor = mode => MODE_COLORS[mode] || 'text-n-slate-12';

const getStatusTextColor = status => STATUS_COLORS[status] || 'text-n-slate-12';
</script>

<template>
  <div class="gap-4 mx-6">
    <div
      class="px-5 py-5 space-y-6 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak bg-n-solid-2"
    >
      <div
        class="flex flex-col gap-5 justify-between items-start w-full md:flex-row"
      >
        <div>
          <span class="text-heading-3 text-n-slate-12">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.TITLE') }}
          </span>
          <p class="mt-1 text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.DESCRIPTION') }}
          </p>
        </div>
        <ButtonV4
          sm
          solid
          blue
          class="flex-shrink-0"
          @click="handleGoToSettings"
        >
          {{ t('INBOX_MGMT.ACCOUNT_HEALTH.GO_TO_SETTINGS') }}
        </ButtonV4>
      </div>

      <div v-if="healthData" class="grid grid-cols-1 gap-4 xs:grid-cols-2">
        <div
          v-for="item in healthItems"
          :key="item.key"
          class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div class="flex gap-2 items-center">
            <span class="text-body-main font-medium text-n-slate-11">
              {{ item.label }}
            </span>
            <Icon
              v-tooltip.top="item.tooltip"
              icon="i-lucide-info"
              class="flex-shrink-0 w-4 h-4 cursor-help text-n-slate-9"
            />
          </div>
          <div class="flex items-center">
            <span
              v-if="item.type === 'quality'"
              class="inline-flex items-center px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
              :class="getQualityRatingTextColor(item.value)"
            >
              {{ item.value }}
            </span>
            <span
              v-else-if="item.type === 'status'"
              class="inline-flex items-center px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
              :class="getStatusTextColor(item.value)"
            >
              {{ formatStatusDisplay(item.value) }}
            </span>
            <span
              v-else-if="item.type === 'mode'"
              class="inline-flex items-center px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
              :class="getModeStatusTextColor(item.value)"
            >
              {{ formatModeDisplay(item.value) }}
            </span>
            <span
              v-else-if="item.type === 'tier'"
              class="text-label text-n-slate-12"
            >
              {{ formatTierDisplay(item.value) }}
            </span>
            <span v-else class="text-label text-n-slate-12">{{
              item.value
            }}</span>
          </div>
        </div>
      </div>

      <div v-else class="pt-8">
        <div
          class="flex justify-center items-center p-8 text-center text-n-slate-11"
        >
          <div>
            <Icon icon="i-lucide-activity" class="mb-2 w-8 h-8" />
            <p class="text-body-main text-n-slate-11">
              {{ t('INBOX_MGMT.ACCOUNT_HEALTH.NO_DATA') }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
