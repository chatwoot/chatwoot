<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useLocale } from 'shared/composables/useLocale';

import ButtonV4 from 'next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  calling: {
    type: Object,
    required: true,
  },
  isEnablingCalling: {
    type: Boolean,
    default: false,
  },
  isRegisteringWebhook: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['enableCalling', 'registerWebhook']);

const { t, te } = useI18n();
const { resolvedLocale } = useLocale();

const formatDate = value =>
  new Intl.DateTimeFormat(resolvedLocale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));

// Meta may add restriction types we have no copy for; show the raw type rather than a translation key.
const restrictionLabel = ({ type, expires_at: expiresAt }) => {
  const typeKey = `INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.TYPES.${type}`;
  const label = te(typeKey) ? t(typeKey) : type;
  if (!expiresAt) return label;

  const expiry = t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.EXPIRES', {
    date: formatDate(expiresAt),
  });
  return `${label} ${expiry}`;
};

const unverifiedCheck = check => ({
  ...check,
  isHealthy: false,
  statusLabel: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.UNVERIFIED'),
  hints: [t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.UNVERIFIED_HINT')],
  action: null,
});

const metaStatusCheck = computed(() => {
  const check = {
    key: 'metaStatus',
    label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.LABEL'),
    tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.TOOLTIP'),
  };
  const { status } = props.calling.meta_status || {};

  if (status === 'enabled') {
    return {
      ...check,
      isHealthy: true,
      statusLabel: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.ENABLED'),
      hints: [],
      action: null,
    };
  }
  if (status === 'disabled') {
    return {
      ...check,
      isHealthy: false,
      statusLabel: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.DISABLED'),
      hints: [t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.DISABLED_HINT')],
      action: {
        label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.FIX_BUTTON'),
        loading: props.isEnablingCalling,
        onClick: () => emit('enableCalling'),
      },
    };
  }
  return unverifiedCheck(check);
});

const WEBHOOK_HINTS = {
  app_not_subscribed:
    'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.HINTS.APP_NOT_SUBSCRIBED',
  calls_field_missing:
    'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.HINTS.CALLS_FIELD_MISSING',
};

const webhookSubscriptionCheck = computed(() => {
  const check = {
    key: 'webhookSubscription',
    label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.LABEL'),
    tooltip: t(
      'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.TOOLTIP'
    ),
  };
  const { status, reason } = props.calling.webhook_subscription || {};

  if (status === 'configured') {
    return {
      ...check,
      isHealthy: true,
      statusLabel: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.CONFIGURED'
      ),
      hints: [],
      action: null,
    };
  }
  if (status === 'missing') {
    return {
      ...check,
      isHealthy: false,
      statusLabel: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.MISSING'
      ),
      hints: WEBHOOK_HINTS[reason] ? [t(WEBHOOK_HINTS[reason])] : [],
      // Only the WABA subscription is ours to repair; the app's webhook fields live in the Meta App Dashboard.
      action:
        reason === 'app_not_subscribed'
          ? {
              label: t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_BUTTON'),
              loading: props.isRegisteringWebhook,
              onClick: () => emit('registerWebhook'),
            }
          : null,
    };
  }
  return unverifiedCheck(check);
});

const eligibilityCheck = computed(() => {
  const check = {
    key: 'eligibility',
    label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.LABEL'),
    tooltip: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.TOOLTIP'),
    action: null,
  };
  const { status, restrictions = [] } = props.calling.eligibility || {};

  if (status === 'eligible') {
    return {
      ...check,
      isHealthy: true,
      statusLabel: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.ELIGIBLE'),
      hints: [],
    };
  }
  if (status === 'restricted') {
    return {
      ...check,
      isHealthy: false,
      statusLabel: t(
        'INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.RESTRICTED'
      ),
      hints: [
        ...restrictions.map(restrictionLabel),
        t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.RESTRICTION_HINT'),
      ],
    };
  }
  return unverifiedCheck(check);
});

const checks = computed(() => [
  metaStatusCheck.value,
  webhookSubscriptionCheck.value,
  eligibilityCheck.value,
]);
</script>

<template>
  <section>
    <h3 class="text-heading-4 text-n-slate-12">
      {{ t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.TITLE') }}
    </h3>
    <p class="mt-1 mb-3 text-body-main text-n-slate-11">
      {{ t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.DESCRIPTION') }}
    </p>
    <div class="grid grid-cols-1 gap-4 xs:grid-cols-2">
      <div
        v-for="check in checks"
        :key="check.key"
        class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
        :class="{ 'xs:col-span-2': check.hints.length }"
      >
        <div class="flex gap-2 items-center">
          <span class="text-body-main font-medium text-n-slate-11">
            {{ check.label }}
          </span>
          <Icon
            v-tooltip.top="check.tooltip"
            icon="i-lucide-info"
            class="flex-shrink-0 w-4 h-4 cursor-help text-n-slate-9"
          />
        </div>
        <div class="flex items-center justify-between gap-3">
          <span
            class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
            :class="check.isHealthy ? 'text-n-teal-11' : 'text-n-amber-11'"
          >
            <Icon
              :icon="
                check.isHealthy
                  ? 'i-lucide-check-circle'
                  : 'i-lucide-alert-triangle'
              "
              class="w-3.5 h-3.5"
            />
            {{ check.statusLabel }}
          </span>
          <ButtonV4
            v-if="check.action"
            sm
            solid
            blue
            :loading="check.action.loading"
            :disabled="check.action.loading"
            class="flex-shrink-0"
            @click="check.action.onClick"
          >
            {{ check.action.label }}
          </ButtonV4>
        </div>
        <p
          v-for="hint in check.hints"
          :key="hint"
          class="max-w-3xl text-label-small text-n-slate-10"
        >
          {{ hint }}
        </p>
      </div>
    </div>
  </section>
</template>
