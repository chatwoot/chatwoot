<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

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

const toggleEnforceMfa = async value => {
  isEnabled.value = value;
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
  <SettingsToggleSection
    :model-value="isEnabled"
    :header="t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.ENFORCE_MFA.NOTE')"
    :hide-toggle="isSaving"
    @update:model-value="toggleEnforceMfa"
  >
    <template v-if="isSaving" #hiddenToggle>
      <Spinner class="size-4 text-n-slate-11" />
    </template>
  </SettingsToggleSection>
</template>
