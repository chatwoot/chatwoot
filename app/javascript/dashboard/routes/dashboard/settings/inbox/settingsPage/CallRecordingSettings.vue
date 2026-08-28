<script setup>
import { ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
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

// Applies both toggles optimistically and rolls them back if the save fails,
// so the switches never show a state the server didn't accept.
const save = async (recording, transcription) => {
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
</script>

<template>
  <div
    class="relative flex flex-col gap-6"
    :class="{ 'pointer-events-none opacity-60': isSaving }"
  >
    <SettingsToggleSection
      :model-value="recordingEnabled"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.RECORDING.LABEL')"
      :description="$t('INBOX_MGMT.VOICE_CONFIGURATION.RECORDING.DESCRIPTION')"
      :hide-toggle="isSaving"
      @update:model-value="toggleRecording"
    >
      <template v-if="isSaving" #hiddenToggle>
        <Spinner class="size-4 text-n-slate-11" />
      </template>
    </SettingsToggleSection>
    <SettingsToggleSection
      v-if="recordingEnabled"
      :model-value="transcriptionEnabled"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.TRANSCRIPTION.LABEL')"
      :description="
        $t('INBOX_MGMT.VOICE_CONFIGURATION.TRANSCRIPTION.DESCRIPTION')
      "
      :hide-toggle="isSaving"
      @update:model-value="toggleTranscription"
    >
      <template v-if="isSaving" #hiddenToggle>
        <Spinner class="size-4 text-n-slate-11" />
      </template>
    </SettingsToggleSection>
  </div>
</template>
