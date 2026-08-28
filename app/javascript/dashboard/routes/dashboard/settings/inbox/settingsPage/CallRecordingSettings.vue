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

const save = async () => {
  isSaving.value = true;
  try {
    await InboxesAPI.setCallRecording(props.inbox.id, {
      recordingEnabled: recordingEnabled.value,
      transcriptionEnabled: transcriptionEnabled.value,
    });
    await store.dispatch('inboxes/get', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (_) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};

const toggleRecording = value => {
  recordingEnabled.value = value;
  save();
};

const toggleTranscription = value => {
  transcriptionEnabled.value = value;
  save();
};
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
