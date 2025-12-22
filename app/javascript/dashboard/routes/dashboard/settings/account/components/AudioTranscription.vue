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
    const { audio_transcriptions } = currentAccount.value?.settings || {};
    isEnabled.value = !!audio_transcriptions;
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    await updateAccount(settings);
    useAlert(t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.ERROR'));
  }
};

const toggleAudioTranscription = async () => {
  return updateAccountSettings({
    audio_transcriptions: isEnabled.value,
  });
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="toggleAudioTranscription" />
      </div>
    </template>
  </SectionLayout>
</template>
