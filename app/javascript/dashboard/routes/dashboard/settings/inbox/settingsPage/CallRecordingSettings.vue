<script setup>
import { reactive, ref, watch } from 'vue';
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

const flags = reactive({
  recording: props.inbox.recording_enabled !== false,
  transcription: props.inbox.transcription_enabled !== false,
});
const isSaving = ref(false);

watch(
  () => [props.inbox.recording_enabled, props.inbox.transcription_enabled],
  ([recording, transcription]) => {
    flags.recording = recording !== false;
    flags.transcription = transcription !== false;
  }
);

const save = async (key, value) => {
  if (isSaving.value) return;
  const previous = flags[key];
  flags[key] = value;
  isSaving.value = true;
  try {
    await InboxesAPI.setCallRecording(props.inbox.id, {
      recordingEnabled: flags.recording,
      transcriptionEnabled: flags.transcription,
    });
    await store.dispatch('inboxes/get', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (_) {
    flags[key] = previous;
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div
    class="relative flex flex-col gap-6"
    :class="{ 'pointer-events-none opacity-60': isSaving }"
  >
    <SettingsToggleSection
      :model-value="flags.recording"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.RECORDING.LABEL')"
      :description="$t('INBOX_MGMT.VOICE_CONFIGURATION.RECORDING.DESCRIPTION')"
      :hide-toggle="isSaving"
      @update:model-value="save('recording', $event)"
    >
      <template v-if="isSaving" #hiddenToggle>
        <Spinner class="size-4 text-n-slate-11" />
      </template>
    </SettingsToggleSection>
    <SettingsToggleSection
      v-if="flags.recording"
      :model-value="flags.transcription"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.TRANSCRIPTION.LABEL')"
      :description="
        $t('INBOX_MGMT.VOICE_CONFIGURATION.TRANSCRIPTION.DESCRIPTION')
      "
      :hide-toggle="isSaving"
      @update:model-value="save('transcription', $event)"
    >
      <template v-if="isSaving" #hiddenToggle>
        <Spinner class="size-4 text-n-slate-11" />
      </template>
    </SettingsToggleSection>
  </div>
</template>
