<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

// The secret of the Meta app behind a manual Cloud inbox, which is what verifies that its
// webhooks come from Meta. Inboxes set up before it was asked for have none, and their
// webhooks are taken unsigned only while the installation allows it, hence the banner.
const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const appSecret = ref('');
const isUpdating = ref(false);

const isConfigured = computed(() =>
  Boolean(props.inbox.provider_config?.app_secret)
);
const isUpdateDisabled = computed(() => !appSecret.value || isUpdating.value);

watch(
  () => props.inbox.id,
  () => {
    appSecret.value = '';
    isUpdating.value = false;
  }
);

const updateAppSecret = async () => {
  isUpdating.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: {
        provider_config: {
          ...props.inbox.provider_config,
          app_secret: appSecret.value.trim(),
        },
      },
    });
    appSecret.value = '';
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.SUCCESS'));
  } catch {
    // The server only says the credentials were refused; the likely cause is a secret
    // from another Meta app than the token's, which is what the message says.
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <SettingsFieldSection
    :label="t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.TITLE')"
    :help-text="t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.HELP')"
  >
    <div class="flex flex-col gap-2">
      <Banner
        v-if="!isConfigured"
        color="amber"
        data-test-id="missing-app-secret"
      >
        {{ t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.MISSING') }}
      </Banner>
      <div
        v-else
        class="inline-flex w-fit items-center gap-1.5 rounded-md bg-n-alpha-2 px-2 py-1 text-label-small text-n-teal-11"
      >
        <span class="size-1.5 rounded-full bg-n-teal-9" />
        {{ t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.CONFIGURED') }}
      </div>
      <div class="flex flex-1 justify-between items-center">
        <woot-input
          v-model="appSecret"
          type="password"
          class="flex-1 mr-2 [&>input]:!mb-0"
          :placeholder="
            t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.PLACEHOLDER')
          "
        />
        <NextButton
          :disabled="isUpdateDisabled"
          :is-loading="isUpdating"
          @click="updateAppSecret"
        >
          {{
            isConfigured
              ? t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.REPLACE')
              : t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.ADD')
          }}
        </NextButton>
      </div>
    </div>
  </SettingsFieldSection>
</template>
