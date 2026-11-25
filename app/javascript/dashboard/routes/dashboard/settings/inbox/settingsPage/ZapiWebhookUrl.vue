<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

// The address Z-API posts this inbox's events to carries the inbox's webhook key, so a leaked
// address is a leaked credential. A new one replaces it; the server keeps the old one open
// until Z-API has taken the new one, so a failed attempt leaves the inbox receiving.
const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const isRotating = ref(false);

const rotateWebhookUrl = async () => {
  isRotating.value = true;
  try {
    await WhatsappChannel.rotateZapiWebhookUrl(props.inbox.id);
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.SUCCESS'));
  } catch {
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.ERROR'));
  } finally {
    isRotating.value = false;
  }
};
</script>

<template>
  <SettingsSection
    :title="t('INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.TITLE')"
    :sub-title="t('INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.HELP')"
  >
    <NextButton
      class="w-fit"
      data-test-id="rotate-zapi-webhook-url"
      :is-loading="isRotating"
      :disabled="isRotating"
      @click="rotateWebhookUrl"
    >
      {{ t('INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.BUTTON') }}
    </NextButton>
  </SettingsSection>
</template>
