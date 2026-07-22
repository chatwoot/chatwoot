<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

import ButtonV4 from 'next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
  healthError: {
    type: Object,
    default: null,
  },
  isEmbeddedSignup: {
    type: Boolean,
    default: false,
  },
  isRegisteringWebhook: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['registerWebhook', 'goToConfiguration']);

const { t, te, locale } = useI18n();

const QUALITY_COLORS = {
  GREEN: 'text-n-teal-11',
  YELLOW: 'text-n-amber-11',
  RED: 'text-n-ruby-11',
  UNKNOWN: 'text-n-slate-12',
};

const STATUS_COLORS = {
  APPROVED: 'text-n-teal-11',
  CONNECTED: 'text-n-teal-11',
  VERIFIED: 'text-n-teal-11',
  STANDARD: 'text-n-teal-11',
  ACTIVE: 'text-n-teal-11',
  PENDING_REVIEW: 'text-n-amber-11',
  AVAILABLE_WITHOUT_REVIEW: 'text-n-teal-11',
  EXPIRED: 'text-n-amber-11',
  FLAGGED: 'text-n-amber-11',
  RESTRICTED: 'text-n-ruby-9',
  BANNED: 'text-n-ruby-9',
  DISCONNECTED: 'text-n-ruby-9',
  REJECTED: 'text-n-ruby-9',
  DECLINED: 'text-n-ruby-9',
};

const MODE_COLORS = {
  LIVE: 'text-n-teal-11',
  SANDBOX: 'text-n-slate-11',
};

const formatStatusDisplay = status => {
  const translationKey = `INBOX_MGMT.ACCOUNT_HEALTH.VALUES.STATUSES.${status}`;

  if (te(translationKey)) {
    return t(translationKey);
  }

  return status
    .toLowerCase()
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
};

const formatDateTime = value => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;

  return new Intl.DateTimeFormat(locale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
};

const healthSections = computed(() => {
  if (!props.healthData) {
    return [];
  }

  const {
    id: phoneNumberId,
    display_phone_number: displayPhoneNumber,
    verified_name: verifiedName,
    name_status: nameStatus,
    quality_rating: qualityRating,
    messaging_limit_tier: messagingLimitTier,
    account_mode: accountMode,
    status: phoneNumberStatus,
    code_verification_status: codeVerificationStatus,
    throughput_level: throughputLevel,
    last_onboarded_time: lastOnboardedTime,
    is_on_biz_app: isOnBizApp,
    platform_type: platformType,
    business_account_id: businessAccountId,
    business_account_name: businessAccountName,
    business_portfolio_id: businessPortfolioId,
    business_portfolio_name: businessPortfolioName,
  } = props.healthData;

  const notAvailable = t('INBOX_MGMT.ACCOUNT_HEALTH.VALUES.NOT_AVAILABLE');

  return [
    {
      key: 'phoneNumber',
      title: t('INBOX_MGMT.ACCOUNT_HEALTH.SECTIONS.PHONE_NUMBER'),
      items: [
        {
          key: 'displayPhoneNumber',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.LABEL'
          ),
          value: displayPhoneNumber || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.TOOLTIP'
          ),
        },
        {
          key: 'verifiedName',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.LABEL'),
          value: verifiedName || notAvailable,
          tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.TOOLTIP'),
        },
        {
          key: 'phoneNumberId',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.PHONE_NUMBER_ID.LABEL'),
          value: phoneNumberId || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.PHONE_NUMBER_ID.TOOLTIP'
          ),
        },
        {
          key: 'coexistence',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.COEXISTENCE.LABEL'),
          value: 'ACTIVE',
          tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.COEXISTENCE.TOOLTIP'),
          type: 'status',
          show: isOnBizApp === true && platformType === 'CLOUD_API',
        },
        {
          key: 'displayNameStatus',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.LABEL'
          ),
          value: nameStatus || 'UNKNOWN',
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.TOOLTIP'
          ),
          type: 'status',
        },
        {
          key: 'lastOnboardedTime',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.LAST_ONBOARDED_TIME.LABEL'
          ),
          value: lastOnboardedTime
            ? formatDateTime(lastOnboardedTime)
            : notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.LAST_ONBOARDED_TIME.TOOLTIP'
          ),
          show: Boolean(lastOnboardedTime),
        },
      ],
    },
    {
      key: 'healthAndCapacity',
      title: t('INBOX_MGMT.ACCOUNT_HEALTH.SECTIONS.HEALTH_AND_CAPACITY'),
      items: [
        {
          key: 'phoneNumberStatus',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.PHONE_NUMBER_STATUS.LABEL'
          ),
          value: phoneNumberStatus || 'UNKNOWN',
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.PHONE_NUMBER_STATUS.TOOLTIP'
          ),
          type: 'status',
        },
        {
          key: 'qualityRating',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.LABEL'),
          value: qualityRating || 'UNKNOWN',
          tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.TOOLTIP'),
          type: 'quality',
        },
        {
          key: 'messagingLimitTier',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.LABEL'
          ),
          value: messagingLimitTier || 'UNKNOWN',
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.TOOLTIP'
          ),
          type: 'tier',
        },
        {
          key: 'accountMode',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.LABEL'),
          value: accountMode || 'UNKNOWN',
          tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.TOOLTIP'),
          type: 'mode',
        },
        {
          key: 'codeVerificationStatus',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.CODE_VERIFICATION_STATUS.LABEL'
          ),
          value: codeVerificationStatus || 'UNKNOWN',
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.CODE_VERIFICATION_STATUS.TOOLTIP'
          ),
          type: 'status',
        },
        {
          key: 'throughputLevel',
          label: t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.THROUGHPUT_LEVEL.LABEL'),
          value: throughputLevel || 'UNKNOWN',
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.THROUGHPUT_LEVEL.TOOLTIP'
          ),
          type: 'status',
        },
      ],
    },
    {
      key: 'businessAccount',
      title: t('INBOX_MGMT.ACCOUNT_HEALTH.SECTIONS.BUSINESS_ACCOUNT'),
      items: [
        {
          key: 'businessAccountName',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_ACCOUNT_NAME.LABEL'
          ),
          value: businessAccountName || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_ACCOUNT_NAME.TOOLTIP'
          ),
        },
        {
          key: 'businessAccountId',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_ACCOUNT_ID.LABEL'
          ),
          value: businessAccountId || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_ACCOUNT_ID.TOOLTIP'
          ),
        },
        {
          key: 'businessPortfolioName',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_PORTFOLIO_NAME.LABEL'
          ),
          value: businessPortfolioName || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_PORTFOLIO_NAME.TOOLTIP'
          ),
        },
        {
          key: 'businessPortfolioId',
          label: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_PORTFOLIO_ID.LABEL'
          ),
          value: businessPortfolioId || notAvailable,
          tooltip: t(
            'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.BUSINESS_PORTFOLIO_ID.TOOLTIP'
          ),
        },
      ],
    },
  ].map(section => ({
    ...section,
    items: section.items.filter(item => item.show !== false),
  }));
});

const errorState = computed(() => {
  if (!props.healthError) return null;

  if (props.healthError.type === 'authorization') {
    return {
      title: props.isEmbeddedSignup
        ? t('INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.AUTHORIZATION.EMBEDDED_TITLE')
        : t('INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.AUTHORIZATION.MANUAL_TITLE'),
      description: props.isEmbeddedSignup
        ? t(
            'INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.AUTHORIZATION.EMBEDDED_DESCRIPTION'
          )
        : t(
            'INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.AUTHORIZATION.MANUAL_DESCRIPTION'
          ),
      showConfigurationAction: true,
    };
  }

  return {
    title: t('INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.GENERIC_TITLE'),
    description: t('INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.GENERIC_DESCRIPTION'),
    showConfigurationAction: false,
  };
});

const handleGoToSettings = () => {
  const {
    business_account_id: businessAccountId,
    business_portfolio_id: businessPortfolioId,
  } = props.healthData || {};

  if (businessPortfolioId && businessAccountId) {
    const whatsappBusinessUrl = new URL(
      'https://business.facebook.com/latest/whatsapp_manager/phone_numbers/'
    );
    whatsappBusinessUrl.searchParams.set('business_id', businessPortfolioId);
    whatsappBusinessUrl.searchParams.set('asset_id', businessAccountId);
    window.open(whatsappBusinessUrl.toString(), '_blank');
  } else {
    const fallbackUrl = 'https://business.facebook.com/';
    window.open(fallbackUrl, '_blank');
  }
};

const getQualityRatingTextColor = rating =>
  QUALITY_COLORS[rating] || QUALITY_COLORS.UNKNOWN;

const formatTierDisplay = tier => {
  const translationKey = `INBOX_MGMT.ACCOUNT_HEALTH.VALUES.TIERS.${tier}`;

  return te(translationKey) ? t(translationKey) : formatStatusDisplay(tier);
};

const formatModeDisplay = mode => {
  const translationKey = `INBOX_MGMT.ACCOUNT_HEALTH.VALUES.MODES.${mode}`;

  return te(translationKey) ? t(translationKey) : formatStatusDisplay(mode);
};

const getModeStatusTextColor = mode => MODE_COLORS[mode] || 'text-n-slate-12';

const getStatusTextColor = status => STATUS_COLORS[status] || 'text-n-slate-12';

const showWebhookSection = computed(
  () => props.healthData?.webhook_configuration !== undefined
);

// Phone-level override takes precedence over WABA-level (application), so prefer it.
const webhookUrl = computed(
  () =>
    props.healthData?.webhook_configuration?.phone_number ||
    props.healthData?.webhook_configuration?.whatsapp_business_account ||
    props.healthData?.webhook_configuration?.application
);

const webhookConfigured = computed(() => !!webhookUrl.value);

const webhookUrlMismatch = computed(
  () =>
    webhookConfigured.value &&
    webhookUrl.value !== props.healthData?.expected_webhook_url
);

const handleRegisterWebhook = () => {
  emit('registerWebhook');
};

const handleGoToConfiguration = () => {
  emit('goToConfiguration');
};

const handleCopyWebhookUrl = async url => {
  await copyTextToClipboard(url);
  useAlert(t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.COPY_SUCCESS'));
};
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

      <div v-if="healthData && !errorState" class="space-y-6">
        <section v-for="section in healthSections" :key="section.key">
          <h3 class="mb-3 text-heading-4 text-n-slate-12">
            {{ section.title }}
          </h3>
          <div class="grid grid-cols-1 gap-4 xs:grid-cols-2">
            <div
              v-for="item in section.items"
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
                <span v-else class="text-label text-n-slate-12">
                  {{ item.value }}
                </span>
              </div>
            </div>
          </div>
        </section>

        <!-- Webhook configuration card -->
        <div
          v-if="showWebhookSection"
          class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div class="flex gap-2 items-center">
            <span class="text-body-main font-medium text-n-slate-11">
              {{ t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.TITLE') }}
            </span>
            <Icon
              v-tooltip.top="t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.DESCRIPTION')"
              icon="i-lucide-info"
              class="flex-shrink-0 w-4 h-4 cursor-help text-n-slate-9"
            />
          </div>
          <div class="flex items-center justify-between gap-3">
            <span
              v-if="webhookConfigured && !webhookUrlMismatch"
              class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2 text-n-teal-11"
            >
              <Icon icon="i-lucide-check-circle" class="w-3.5 h-3.5" />
              {{ t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.CONFIGURED_SUCCESS') }}
            </span>
            <span
              v-else
              class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2 text-n-amber-11"
            >
              <Icon icon="i-lucide-alert-triangle" class="w-3.5 h-3.5" />
              {{
                webhookUrlMismatch
                  ? t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.URL_MISMATCH')
                  : t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.ACTION_REQUIRED')
              }}
            </span>
            <ButtonV4
              v-if="!webhookConfigured || webhookUrlMismatch"
              sm
              solid
              blue
              :loading="isRegisteringWebhook"
              :disabled="isRegisteringWebhook"
              class="flex-shrink-0"
              @click="handleRegisterWebhook"
            >
              {{ t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_BUTTON') }}
            </ButtonV4>
          </div>
          <div v-if="webhookConfigured" class="pt-1 space-y-2">
            <div class="flex items-center gap-3 min-w-0">
              <span class="flex-shrink-0 text-label-small text-n-slate-10">
                {{ t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.CONFIGURED_URL') }}
              </span>
              <span
                v-tooltip.top="webhookUrl"
                class="flex-1 min-w-0 font-mono text-label-small truncate text-n-slate-12"
              >
                {{ webhookUrl }}
              </span>
              <ButtonV4
                v-tooltip.top="t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.COPY_URL')"
                type="button"
                ghost
                sm
                slate
                icon="i-lucide-copy"
                class="flex-shrink-0"
                :aria-label="t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.COPY_URL')"
                @click="handleCopyWebhookUrl(webhookUrl)"
              />
            </div>
            <div
              v-if="webhookUrlMismatch"
              class="flex items-center gap-3 min-w-0"
            >
              <span class="flex-shrink-0 text-label-small text-n-slate-10">
                {{ t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.EXPECTED_URL') }}
              </span>
              <span
                v-tooltip.top="healthData.expected_webhook_url"
                class="flex-1 min-w-0 font-mono text-label-small truncate text-n-slate-12"
              >
                {{ healthData.expected_webhook_url }}
              </span>
              <ButtonV4
                v-tooltip.top="t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.COPY_URL')"
                type="button"
                ghost
                sm
                slate
                icon="i-lucide-copy"
                class="flex-shrink-0"
                :aria-label="t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.COPY_URL')"
                @click="handleCopyWebhookUrl(healthData.expected_webhook_url)"
              />
            </div>
          </div>
        </div>
      </div>

      <div v-else-if="errorState" class="pt-2">
        <div
          class="flex flex-col gap-4 p-5 rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div class="flex gap-3 items-start">
            <Icon
              icon="i-lucide-alert-triangle"
              class="flex-shrink-0 mt-0.5 w-5 h-5 text-n-amber-11"
            />
            <div class="min-w-0">
              <h3 class="text-heading-4 text-n-slate-12">
                {{ errorState.title }}
              </h3>
              <p class="mt-1 text-body-main text-n-slate-11">
                {{ errorState.description }}
              </p>
            </div>
          </div>
          <div
            v-if="healthError.message"
            class="p-3 rounded-lg bg-n-alpha-1 text-label-small text-n-slate-11"
          >
            <p class="break-words">{{ healthError.message }}</p>
          </div>
          <div v-if="errorState.showConfigurationAction">
            <ButtonV4 sm solid blue @click="handleGoToConfiguration">
              {{ t('INBOX_MGMT.ACCOUNT_HEALTH.ERRORS.GO_TO_CONFIGURATION') }}
            </ButtonV4>
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
