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
  isRegisteringWebhook: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['registerWebhook']);

const { t } = useI18n();

const WEBHOOK_LABELS = {
  messaging: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.MESSAGING',
  voice: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE',
  voice_status: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE_STATUS',
  voice_app: 'INBOX_MGMT.TWILIO_HEALTH.WEBHOOKS.VOICE_APP',
};

const webhooks = computed(() =>
  (props.healthData?.webhooks || []).map(webhook => ({
    ...webhook,
    label: t(WEBHOOK_LABELS[webhook.name]),
    tooltip: t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.TOOLTIP', {
      expected: webhook.expected,
      actual: webhook.actual || t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.NOT_SET'),
    }),
  }))
);

const handleRegisterWebhook = () => emit('registerWebhook');
</script>

<template>
  <div class="gap-4 mx-6">
    <div
      class="px-5 py-5 space-y-6 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak bg-n-solid-2"
    >
      <div>
        <span class="text-heading-3 text-n-slate-12">
          {{ t('INBOX_MGMT.TWILIO_HEALTH.TITLE') }}
        </span>
        <p class="mt-1 text-body-main text-n-slate-11">
          {{ t('INBOX_MGMT.TWILIO_HEALTH.DESCRIPTION') }}
        </p>
      </div>

      <div v-if="healthData" class="grid grid-cols-1 gap-4 xs:grid-cols-2">
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
          <div class="flex gap-3 justify-between items-center">
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
              {{
                webhook.actual
                  ? t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.URL_MISMATCH')
                  : t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.ACTION_REQUIRED')
              }}
            </span>
            <ButtonV4
              v-if="!webhook.configured"
              sm
              solid
              blue
              :loading="isRegisteringWebhook"
              :disabled="isRegisteringWebhook"
              class="flex-shrink-0"
              @click="handleRegisterWebhook"
            >
              {{ t('INBOX_MGMT.TWILIO_HEALTH.WEBHOOK.REGISTER_BUTTON') }}
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
              {{ t('INBOX_MGMT.TWILIO_HEALTH.NO_DATA') }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
