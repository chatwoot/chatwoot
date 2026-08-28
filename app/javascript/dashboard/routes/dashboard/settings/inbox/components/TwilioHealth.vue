<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import ButtonV4 from 'next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import InboxHealthState from './InboxHealthState.vue';

const props = defineProps({
  healthData: {
    type: Object,
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
  isRegisteringWebhook: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['registerWebhook']);

const { t, te } = useI18n();

// Twilio can return values we have no copy for (a new account type, an unknown capability);
// fall back to the raw value rather than leaking a translation key into the UI.
const translate = (key, fallback, named) =>
  te(key) ? t(key, named ?? {}) : fallback;

const CONSOLE_URLS = {
  phone_number:
    'https://console.twilio.com/us1/develop/phone-numbers/manage/incoming',
  messaging_service: 'https://console.twilio.com/us1/develop/sms/services',
};

const ACCOUNT_STATUS_COLORS = {
  ACTIVE: 'text-n-teal-11',
  SUSPENDED: 'text-n-ruby-11',
  CLOSED: 'text-n-ruby-11',
};

// Trial accounts only reach numbers verified with Twilio, so they warrant a warning colour.
const ACCOUNT_TYPE_COLORS = {
  FULL: 'text-n-teal-11',
  TRIAL: 'text-n-amber-11',
};

const WEBHOOK_LABELS = {
  messaging: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.MESSAGING',
  voice: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE',
  voice_status: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE_STATUS',
  voice_app: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE_APP',
};

// Only these reasons are ours to fix from here; the rest need a change in the Twilio Console.
const REGISTERABLE_REASONS = [
  'not_set',
  'url_mismatch',
  'wrong_http_method',
  'overridden_by_number',
  'missing_twiml_app',
];

// Only the capabilities this inbox actually depends on; MMS is never required.
const CAPABILITIES = ['sms', 'voice'];

const toKey = value => String(value || 'unknown').toUpperCase();

// Absent when the credentials are a restricted API key that cannot read the Account resource.
const account = computed(() => props.healthData?.account ?? null);
const sender = computed(() => props.healthData?.sender ?? {});

const isHealthy = computed(() => props.healthData?.status === 'healthy');

const requiredCapabilities = computed(() =>
  props.healthData?.voice_enabled ? ['sms', 'voice'] : ['sms']
);

const capabilities = computed(() => {
  const available = sender.value.capabilities ?? {};
  return CAPABILITIES.map(name => ({
    name,
    label: translate(
      `INBOX_MGMT.TWILIO_HEALTH.VALUES.CAPABILITIES.${toKey(name)}`,
      name.toUpperCase()
    ),
    available: Boolean(available[name]),
    required: requiredCapabilities.value.includes(name),
  }));
});

const healthItems = computed(() => {
  if (!props.healthData) return [];

  return [
    {
      key: 'accountName',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_NAME.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_NAME.TOOLTIP'),
      value: account.value?.friendly_name || account.value?.sid,
      show: Boolean(account.value),
    },
    {
      key: 'accountStatus',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_STATUS.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_STATUS.TOOLTIP'),
      value: translate(
        `INBOX_MGMT.TWILIO_HEALTH.VALUES.ACCOUNT_STATUSES.${toKey(account.value?.status)}`,
        account.value?.status
      ),
      type: 'pill',
      color: ACCOUNT_STATUS_COLORS[toKey(account.value?.status)],
      show: Boolean(account.value),
    },
    {
      key: 'accountType',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_TYPE.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.ACCOUNT_TYPE.TOOLTIP'),
      value: translate(
        `INBOX_MGMT.TWILIO_HEALTH.VALUES.ACCOUNT_TYPES.${toKey(account.value?.type)}`,
        account.value?.type
      ),
      type: 'pill',
      color: ACCOUNT_TYPE_COLORS[toKey(account.value?.type)],
      show: Boolean(account.value),
    },
    {
      key: 'sender',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.SENDER.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.SENDER.TOOLTIP'),
      value: sender.value.label,
      caption: translate(
        `INBOX_MGMT.TWILIO_HEALTH.VALUES.SENDER_TYPES.${toKey(sender.value.type)}`,
        sender.value.type
      ),
    },
    {
      key: 'capabilities',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.CAPABILITIES.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.CAPABILITIES.TOOLTIP'),
      type: 'capabilities',
      show: sender.value.type === 'phone_number',
    },
    {
      key: 'voiceCalling',
      label: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.VOICE_CALLING.LABEL'),
      tooltip: t('INBOX_MGMT.TWILIO_HEALTH.FIELDS.VOICE_CALLING.TOOLTIP'),
      value: props.healthData.voice_enabled
        ? t('INBOX_MGMT.TWILIO_HEALTH.VALUES.ENABLED')
        : t('INBOX_MGMT.TWILIO_HEALTH.VALUES.DISABLED'),
      type: 'pill',
      color: props.healthData.voice_enabled
        ? 'text-n-teal-11'
        : 'text-n-slate-11',
    },
  ].filter(item => item.show !== false);
});

const webhooks = computed(() =>
  (props.healthData?.webhooks || []).map(webhook => ({
    ...webhook,
    label: t(WEBHOOK_LABELS[webhook.name]),
    reasonLabel: translate(
      `INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.REASONS.${toKey(webhook.reason)}`,
      t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.REASONS.NOT_SET')
    ),
    hint: translate(
      `INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.HINTS.${toKey(webhook.reason)}`,
      t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.HINTS.NOT_SET'),
      { method: webhook.method }
    ),
    tooltip: [
      `${t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.EXPECTED')}: ${webhook.expected}`,
      `${t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.CURRENT')}: ${
        webhook.actual || t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.NOT_SET')
      }`,
    ].join('\n'),
    canRegister: REGISTERABLE_REASONS.includes(webhook.reason),
  }))
);

// One button repoints every webhook, so it shows if any single one is ours to fix.
const canRegisterWebhooks = computed(() =>
  webhooks.value.some(webhook => webhook.canRegister)
);

// Several webhooks usually break for the same reason; explain each distinct one once.
const webhookNotes = computed(() => {
  const seen = new Set();
  return webhooks.value
    .filter(webhook => !webhook.configured)
    .filter(webhook => !seen.has(webhook.hint) && seen.add(webhook.hint))
    .map(({ reason, reasonLabel, hint }) => ({ reason, reasonLabel, hint }));
});

const consoleUrl = computed(
  () => CONSOLE_URLS[sender.value.type] || CONSOLE_URLS.phone_number
);

const capabilityColor = capability => {
  if (capability.available) return 'text-n-teal-11';
  return capability.required ? 'text-n-ruby-11' : 'text-n-slate-11';
};

const handleGoToConsole = () => window.open(consoleUrl.value, '_blank');

const handleRegisterWebhook = () => emit('registerWebhook');
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
          <div class="flex gap-2 items-center">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.TWILIO_HEALTH.TITLE') }}
            </span>
            <span
              v-if="healthData"
              class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
              :class="isHealthy ? 'text-n-teal-11' : 'text-n-amber-11'"
            >
              <Icon
                :icon="
                  isHealthy
                    ? 'i-lucide-check-circle'
                    : 'i-lucide-alert-triangle'
                "
                class="w-3.5 h-3.5"
              />
              {{
                isHealthy
                  ? t('INBOX_MGMT.TWILIO_HEALTH.STATUS.HEALTHY')
                  : t('INBOX_MGMT.TWILIO_HEALTH.STATUS.MISCONFIGURED')
              }}
            </span>
          </div>
          <p class="mt-1 text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.TWILIO_HEALTH.DESCRIPTION') }}
          </p>
        </div>
        <ButtonV4
          sm
          solid
          blue
          class="flex-shrink-0"
          @click="handleGoToConsole"
        >
          {{ t('INBOX_MGMT.TWILIO_HEALTH.GO_TO_SETTINGS') }}
        </ButtonV4>
      </div>

      <template v-if="healthData && !isLoading && !error">
        <div class="grid grid-cols-1 gap-4 xs:grid-cols-2">
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
            <div class="flex flex-wrap gap-2 items-center">
              <template v-if="item.type === 'capabilities'">
                <span
                  v-for="capability in capabilities"
                  :key="capability.name"
                  class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
                  :class="capabilityColor(capability)"
                >
                  <Icon
                    :icon="
                      capability.available ? 'i-lucide-check' : 'i-lucide-x'
                    "
                    class="w-3.5 h-3.5"
                  />
                  {{ capability.label }}
                </span>
              </template>
              <span
                v-else-if="item.type === 'pill'"
                class="inline-flex items-center px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2"
                :class="item.color || 'text-n-slate-12'"
              >
                {{ item.value }}
              </span>
              <template v-else>
                <span class="text-label text-n-slate-12">{{ item.value }}</span>
                <span
                  v-if="item.caption"
                  class="text-label-small text-n-slate-11"
                >
                  {{ item.caption }}
                </span>
              </template>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div
            class="flex flex-col gap-5 justify-between items-start w-full md:flex-row"
          >
            <div>
              <span class="text-heading-3 text-n-slate-12">
                {{ t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.TITLE') }}
              </span>
              <p class="mt-1 text-body-main text-n-slate-11">
                {{ t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.DESCRIPTION') }}
              </p>
            </div>
            <ButtonV4
              v-if="canRegisterWebhooks"
              sm
              solid
              blue
              :loading="isRegisteringWebhook"
              :disabled="isRegisteringWebhook"
              class="flex-shrink-0"
              @click="handleRegisterWebhook"
            >
              {{ t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.REGISTER_ALL') }}
            </ButtonV4>
          </div>

          <div class="grid grid-cols-1 gap-4 xs:grid-cols-2">
            <div
              v-for="webhook in webhooks"
              :key="webhook.name"
              class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
            >
              <div class="flex gap-2 items-center">
                <span class="text-body-main font-medium text-n-slate-11">
                  {{ webhook.label }}
                </span>
                <Icon
                  v-tooltip.top="webhook.tooltip"
                  icon="i-lucide-info"
                  class="flex-shrink-0 w-4 h-4 cursor-help text-n-slate-9"
                />
              </div>
              <div class="flex items-center">
                <span
                  v-if="webhook.configured"
                  class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2 text-n-teal-11"
                >
                  <Icon icon="i-lucide-check-circle" class="w-3.5 h-3.5" />
                  {{ t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.CONFIGURED_SUCCESS') }}
                </span>
                <span
                  v-else
                  class="inline-flex items-center gap-1.5 px-2 py-0.5 min-h-6 text-label-small rounded-md bg-n-alpha-2 text-n-amber-11"
                >
                  <Icon icon="i-lucide-alert-triangle" class="w-3.5 h-3.5" />
                  {{ webhook.reasonLabel }}
                </span>
              </div>
            </div>
          </div>

          <div v-if="webhookNotes.length" class="flex flex-col gap-2">
            <p
              v-for="note in webhookNotes"
              :key="note.reason"
              class="text-label-small text-n-slate-11"
            >
              <span class="text-n-amber-11">{{ note.reasonLabel }}</span>
              &mdash; {{ note.hint }}
            </p>
          </div>
        </div>
      </template>

      <InboxHealthState
        v-else
        :is-loading="isLoading"
        :error="error"
        :loading-label="t('INBOX_MGMT.TWILIO_HEALTH.LOADING')"
        :error-title="t('INBOX_MGMT.TWILIO_HEALTH.ERROR_TITLE')"
        :empty-label="t('INBOX_MGMT.TWILIO_HEALTH.NO_DATA')"
      />
    </div>
  </div>
</template>
