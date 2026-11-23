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

const { t } = useI18n();
const { resolvedLocale } = useLocale();

const HEALTHY_STATUSES = ['enabled', 'configured', 'eligible'];

const formatDate = value =>
  new Intl.DateTimeFormat(resolvedLocale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));

const checks = computed(() => {
  const {
    meta_status: metaStatus,
    webhook_subscription: webhook,
    eligibility,
  } = props.calling;
  const isCallingDisabled = metaStatus.status === 'disabled';

  return [
    {
      key: 'metaStatus',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.LABEL'),
      status: metaStatus.status,
      hints: isCallingDisabled
        ? [t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.DISABLED_HINT')]
        : [],
      action: isCallingDisabled && {
        label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.META_STATUS.FIX_BUTTON'),
        loading: props.isEnablingCalling,
        onClick: () => emit('enableCalling'),
      },
    },
    {
      key: 'webhookSubscription',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.LABEL'),
      status: webhook.status,
      hints: webhook.reason
        ? [
            t(
              `INBOX_MGMT.ACCOUNT_HEALTH.CALLING.WEBHOOK_SUBSCRIPTION.${webhook.reason.toUpperCase()}`
            ),
          ]
        : [],
      // The app's own webhook fields live in the Meta App Dashboard; only the WABA subscription is ours to repair.
      action: webhook.reason === 'app_not_subscribed' && {
        label: t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_BUTTON'),
        loading: props.isRegisteringWebhook,
        onClick: () => emit('registerWebhook'),
      },
    },
    {
      key: 'eligibility',
      label: t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.LABEL'),
      status: eligibility.status,
      hints: (eligibility.restrictions || []).map(({ type, expires_at }) =>
        t(`INBOX_MGMT.ACCOUNT_HEALTH.CALLING.ELIGIBILITY.${type}`, {
          date: formatDate(expires_at),
        })
      ),
      action: false,
    },
  ].map(check => ({
    ...check,
    isHealthy: HEALTHY_STATUSES.includes(check.status),
    statusLabel: t(
      `INBOX_MGMT.ACCOUNT_HEALTH.CALLING.STATUSES.${check.status.toUpperCase()}`
    ),
    hints:
      check.status === 'unverified'
        ? [t('INBOX_MGMT.ACCOUNT_HEALTH.CALLING.UNVERIFIED_HINT')]
        : check.hints,
  }));
});
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
        <span class="text-body-main font-medium text-n-slate-11">
          {{ check.label }}
        </span>
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
