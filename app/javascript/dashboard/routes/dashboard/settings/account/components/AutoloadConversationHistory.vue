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
    const { autoload_conversation_history } =
      currentAccount.value?.settings || {};
    isEnabled.value = !!autoload_conversation_history;
  },
  { deep: true, immediate: true }
);

const toggleAutoloadHistory = async () => {
  try {
    await updateAccount({
      autoload_conversation_history: isEnabled.value,
    });
    useAlert(
      t('GENERAL_SETTINGS.FORM.AUTOLOAD_CONVERSATION_HISTORY.API.SUCCESS')
    );
  } catch (error) {
    useAlert(
      t('GENERAL_SETTINGS.FORM.AUTOLOAD_CONVERSATION_HISTORY.API.ERROR')
    );
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.AUTOLOAD_CONVERSATION_HISTORY.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUTOLOAD_CONVERSATION_HISTORY.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="toggleAutoloadHistory" />
      </div>
    </template>
  </SectionLayout>
</template>
