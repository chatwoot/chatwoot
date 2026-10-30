<script setup>
import { ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsCheckboxOption from './SettingsCheckboxOption.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  // Renders one-line checkboxes instead of toggle cards
  checkbox: {
    type: Boolean,
    default: false,
  },
});

const store = useStore();
const { t } = useI18n();

const recordingEnabled = ref(props.inbox.recording_enabled !== false);
const transcriptionEnabled = ref(props.inbox.transcription_enabled !== false);
const isSaving = ref(false);

watch(
  () => [props.inbox.recording_enabled, props.inbox.transcription_enabled],
  ([recording, transcription]) => {
    recordingEnabled.value = recording !== false;
    transcriptionEnabled.value = transcription !== false;
  }
);

// Mirrors the inbound-calls toggle: apply optimistically, roll back if the save
// fails, so the switches never show a state the server didn't accept.
const save = async (recording, transcription) => {
  if (isSaving.value) return;
  const previous = [recordingEnabled.value, transcriptionEnabled.value];
  recordingEnabled.value = recording;
  transcriptionEnabled.value = transcription;
  isSaving.value = true;
  try {
    await InboxesAPI.setCallRecording(props.inbox.id, {
      recordingEnabled: recording,
      transcriptionEnabled: transcription,
    });
    await store.dispatch('inboxes/get', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (_) {
    [recordingEnabled.value, transcriptionEnabled.value] = previous;
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};

const toggleRecording = value => save(value, transcriptionEnabled.value);

const toggleTranscription = value => save(recordingEnabled.value, value);

const option = key =>
  props.checkbox
    ? { header: t(`INBOX_MGMT.VOICE_CONFIGURATION.OPTIONS.${key}`) }
    : {
        header: t(`INBOX_MGMT.VOICE_CONFIGURATION.${key}.LABEL`),
        description: t(`INBOX_MGMT.VOICE_CONFIGURATION.${key}.DESCRIPTION`),
      };
</script>

<template>
  <div
    class="relative flex flex-col"
    :class="{
      'pointer-events-none opacity-60': isSaving,
      'gap-3': checkbox,
      'gap-6': !checkbox,
    }"
  >
    <component
      :is="checkbox ? SettingsCheckboxOption : SettingsToggleSection"
      v-bind="option('RECORDING')"
      :model-value="recordingEnabled"
      @update:model-value="toggleRecording"
    />
    <component
      :is="checkbox ? SettingsCheckboxOption : SettingsToggleSection"
      v-if="recordingEnabled"
      v-bind="option('TRANSCRIPTION')"
      :model-value="transcriptionEnabled"
      @update:model-value="toggleTranscription"
    />
  </div>
</template>
