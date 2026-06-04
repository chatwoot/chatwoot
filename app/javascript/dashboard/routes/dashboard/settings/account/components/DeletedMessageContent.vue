<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const isEnabled = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { show_deleted_message_content } =
      currentAccount.value?.settings || {};
    isEnabled.value = !!show_deleted_message_content;
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async () => {
  try {
    await updateAccount({
      show_deleted_message_content: isEnabled.value,
    });
    useAlert(t('GENERAL_SETTINGS.FORM.DELETED_MESSAGE_CONTENT.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.DELETED_MESSAGE_CONTENT.API.ERROR'));
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.DELETED_MESSAGE_CONTENT.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.DELETED_MESSAGE_CONTENT.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="updateAccountSettings" />
      </div>
    </template>
  </SectionLayout>
</template>
