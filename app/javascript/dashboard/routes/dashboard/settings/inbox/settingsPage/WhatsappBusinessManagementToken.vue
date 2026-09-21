<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_GUIDE_URL = 'https://chwt.app/zM7G2yU';
const businessManagementToken = ref('');
const isUpdating = ref(false);
const tokenUpdated = ref(false);
const isTokenConfigured = computed(
  () =>
    tokenUpdated.value ||
    Boolean(props.inbox.business_management_token_configured)
);
const isUpdateDisabled = computed(
  () => !businessManagementToken.value || isUpdating.value
);
const sectionTitle = computed(() =>
  isTokenConfigured.value
    ? t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_REPLACE_TITLE'
      )
    : t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_ADD_TITLE'
      )
);
const actionLabel = computed(() =>
  isTokenConfigured.value
    ? t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_REPLACE_BUTTON'
      )
    : t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_ADD_BUTTON'
      )
);

watch(
  () => props.inbox.id,
  () => {
    businessManagementToken.value = '';
    tokenUpdated.value = false;
    isUpdating.value = false;
  }
);

const updateToken = async () => {
  const inboxId = props.inbox.id;
  isUpdating.value = true;
  try {
    await InboxesAPI.updateWhatsappBusinessManagementToken(
      inboxId,
      businessManagementToken.value
    );
    if (props.inbox.id !== inboxId) return;

    businessManagementToken.value = '';
    tokenUpdated.value = true;
    useAlert(
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_SUCCESS'
      )
    );
  } catch (error) {
    if (props.inbox.id !== inboxId) return;

    useAlert(
      error.response?.data?.message ||
        t(
          'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_ERROR'
        )
    );
  } finally {
    if (props.inbox.id === inboxId) {
      isUpdating.value = false;
    }
  }
};
</script>

<template>
  <SettingsFieldSection
    :label="sectionTitle"
    :help-text="
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_SUBHEADER'
      )
    "
  >
    <div class="flex flex-col gap-2">
      <div
        v-if="isTokenConfigured"
        class="inline-flex w-fit items-center gap-1.5 rounded-md bg-n-alpha-2 px-2 py-1 text-label-small text-n-teal-11"
      >
        <span class="size-1.5 rounded-full bg-n-teal-9" />
        {{
          t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_CONFIGURED'
          )
        }}
      </div>
      <div
        class="flex flex-1 justify-between items-center whatsapp-settings--content"
      >
        <woot-input
          v-model="businessManagementToken"
          type="password"
          class="flex-1 mr-2 [&>input]:!mb-0"
          :placeholder="
            t(
              'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_PLACEHOLDER'
            )
          "
        />
        <NextButton
          :disabled="isUpdateDisabled"
          :is-loading="isUpdating"
          @click="updateToken"
        >
          {{ actionLabel }}
        </NextButton>
      </div>
      <a
        :href="WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_GUIDE_URL"
        target="_blank"
        rel="noopener noreferrer"
        class="text-label-small text-n-blue-11 hover:underline"
      >
        {{
          t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_GUIDE_LINK'
          )
        }}
      </a>
    </div>
  </SettingsFieldSection>
</template>
