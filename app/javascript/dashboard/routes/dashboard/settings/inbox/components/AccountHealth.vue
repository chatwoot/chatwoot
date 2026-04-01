<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const QUALITY_COLORS = {
  GREEN: 'text-secondary',
  YELLOW: 'text-amber-11',
  RED: 'text-error',
  UNKNOWN: 'text-on-surface',
};

const STATUS_COLORS = {
  APPROVED: 'text-secondary',
  PENDING_REVIEW: 'text-amber-11',
  AVAILABLE_WITHOUT_REVIEW: 'text-secondary',
  REJECTED: 'text-error',
  DECLINED: 'text-error',
};

const MODE_COLORS = {
  LIVE: 'text-secondary',
  SANDBOX: 'text-on-surface-variant',
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

const getModeStatusTextColor = mode => MODE_COLORS[mode] || 'text-on-surface';

const getStatusTextColor = status => STATUS_COLORS[status] || 'text-on-surface';
</script>

<template>
  <div
    class="mx-8 gap-4 pt-8 text-on-surface antialiased selection:bg-secondary/30"
  >
    <div
      class="space-y-6 rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
    >
      <div
        class="flex w-full flex-col items-start justify-between gap-5 md:flex-row md:items-center"
      >
        <div class="min-w-0">
          <h2 class="text-base font-semibold text-on-surface">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.TITLE') }}
          </h2>
          <p class="mb-0 mt-1 text-sm text-on-primary-container">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.DESCRIPTION') }}
          </p>
        </div>
        <Button
          sm
          solid
          teal
          class="shrink-0"
          :label="t('INBOX_MGMT.ACCOUNT_HEALTH.GO_TO_SETTINGS')"
          @click="handleGoToSettings"
        />
      </div>

      <div v-if="healthData" class="grid grid-cols-1 gap-4 xs:grid-cols-2">
        <div
          v-for="item in healthItems"
          :key="item.key"
          class="flex flex-col gap-2 rounded-lg border border-outline-variant/10 bg-surface-container-lowest p-4"
        >
          <div class="flex items-center gap-2">
            <span
              class="text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
            >
              {{ item.label }}
            </span>
            <Icon
              v-tooltip.top="item.tooltip"
              icon="i-lucide-info"
              class="size-4 shrink-0 cursor-help text-on-surface-variant/50"
            />
          </div>
          <div class="flex items-center">
            <span
              v-if="item.type === 'quality'"
              class="inline-flex min-h-6 items-center rounded-md border border-outline-variant/10 bg-surface-container-high px-2 py-0.5 text-xs font-medium"
              :class="getQualityRatingTextColor(item.value)"
            >
              {{ item.value }}
            </span>
            <span
              v-else-if="item.type === 'status'"
              class="inline-flex min-h-6 items-center rounded-md border border-outline-variant/10 bg-surface-container-high px-2 py-0.5 text-xs font-medium"
              :class="getStatusTextColor(item.value)"
            >
              {{ formatStatusDisplay(item.value) }}
            </span>
            <span
              v-else-if="item.type === 'mode'"
              class="inline-flex min-h-6 items-center rounded-md border border-outline-variant/10 bg-surface-container-high px-2 py-0.5 text-xs font-medium"
              :class="getModeStatusTextColor(item.value)"
            >
              {{ formatModeDisplay(item.value) }}
            </span>
            <span
              v-else-if="item.type === 'tier'"
              class="text-sm font-medium text-on-surface"
            >
              {{ formatTierDisplay(item.value) }}
            </span>
            <span v-else class="text-sm font-medium text-on-surface">{{
              item.value
            }}</span>
          </div>
        </div>
      </div>

      <div v-else class="pt-4">
        <div
          class="flex flex-col items-center justify-center rounded-lg border border-dashed border-outline-variant/25 bg-surface-container-lowest/50 p-10 text-center"
        >
          <Icon
            icon="i-lucide-activity"
            class="mb-3 size-8 text-on-surface-variant/50"
          />
          <p class="mb-0 text-sm text-on-surface-variant">
            {{ t('INBOX_MGMT.ACCOUNT_HEALTH.NO_DATA') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
