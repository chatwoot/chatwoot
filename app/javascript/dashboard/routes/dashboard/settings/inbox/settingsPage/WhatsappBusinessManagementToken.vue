<script setup>
import { computed, ref } from 'vue';
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
const businessManagementToken = ref('');
const isUpdating = ref(false);
const isRemoving = ref(false);
const isUpdateDisabled = computed(
  () => !businessManagementToken.value || isUpdating.value
);

const updateToken = async () => {
  isUpdating.value = true;
  try {
    await InboxesAPI.updateWhatsappBusinessManagementToken(
      props.inbox.id,
      businessManagementToken.value
    );
    businessManagementToken.value = '';
    useAlert(
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_SUCCESS'
      )
    );
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t(
          'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_ERROR'
        )
    );
  } finally {
    isUpdating.value = false;
  }
};

const removeToken = async () => {
  isRemoving.value = true;
  try {
    await InboxesAPI.removeWhatsappBusinessManagementToken(props.inbox.id);
    useAlert(
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_REMOVE_SUCCESS'
      )
    );
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t(
          'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_REMOVE_ERROR'
        )
    );
  } finally {
    isRemoving.value = false;
  }
};
</script>

<template>
  <SettingsFieldSection
    :label="
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_TITLE'
      )
    "
    :help-text="
      t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_UPDATE_SUBHEADER'
      )
    "
  >
    <div class="flex flex-col gap-2">
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
          {{ t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
        </NextButton>
        <NextButton
          color-scheme="alert"
          variant="outline"
          class="ml-2"
          :is-loading="isRemoving"
          :disabled="isUpdating"
          @click="removeToken"
        >
          {{
            t(
              'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_BUSINESS_MANAGEMENT_TOKEN_REMOVE_BUTTON'
            )
          }}
        </NextButton>
      </div>
      <a
        href="https://www.chatwoot.com/hc/user-guide/articles/1785260890-whatsapp-business-token"
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
