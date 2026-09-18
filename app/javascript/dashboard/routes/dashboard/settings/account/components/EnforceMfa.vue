<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const isEnabled = ref(false);
const isSaving = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { enforce_mfa } = currentAccount.value?.settings || {};
    isEnabled.value = enforce_mfa === true;
  },
  { deep: true, immediate: true }
);

const toggleEnforceMfa = async () => {
  isSaving.value = true;
  try {
    await updateAccount({ enforce_mfa: isEnabled.value });
    useAlert(t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.API.SUCCESS'));
  } catch (error) {
    isEnabled.value = currentAccount.value?.settings?.enforce_mfa === true;
    useAlert(t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.API.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch
          v-model="isEnabled"
          :disabled="isSaving"
          @change="toggleEnforceMfa"
        />
      </div>
    </template>
  </SectionLayout>
</template>
