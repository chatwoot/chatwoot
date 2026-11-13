<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'dashboard/components-next/select/Select.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import { durationOptions } from './callDurations';

// Wrap-up time and what is kept from each call
const props = defineProps({
  // The wrap-up time the inbox saved, kept selectable when it is not a preset
  savedCooldownSeconds: {
    type: Number,
    default: null,
  },
});

const callCooldownSeconds = defineModel('callCooldownSeconds', {
  type: Number,
});
const recordingEnabled = defineModel('recordingEnabled', { type: Boolean });
const transcriptionEnabled = defineModel('transcriptionEnabled', {
  type: Boolean,
});

// Within the 0–600 s wrap-up the server accepts
const WRAP_UP_PRESETS = [0, 30, 60, 120, 300];

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.AFTER_CALL.${key}`);
const wrapUpOptions = computed(() =>
  durationOptions(t, WRAP_UP_PRESETS, props.savedCooldownSeconds)
);

// A call that isn't recorded has nothing to transcribe, so transcription shows off while recording is
watch(recordingEnabled, recording => {
  if (!recording) transcriptionEnabled.value = false;
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col gap-1.5">
      <label
        class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
      >
        {{ label('WRAP_UP') }}
        <Select
          v-model="callCooldownSeconds"
          :options="wrapUpOptions"
          :aria-label="label('WRAP_UP')"
        />
      </label>
      <p class="text-body-main text-n-slate-11">
        {{ label('WRAP_UP_HELP') }}
      </p>
    </div>
    <div
      class="flex flex-col divide-y divide-n-weak rounded-xl outline outline-1 -outline-offset-1 outline-n-weak [&>label]:px-4 [&>label]:py-3"
    >
      <CallSettingsOption
        v-model="recordingEnabled"
        :label="label('RECORD')"
        :help="label('RECORD_HELP')"
      />
      <CallSettingsOption
        :model-value="recordingEnabled && transcriptionEnabled"
        :disabled="!recordingEnabled"
        :label="label('TRANSCRIBE')"
        :help="label('TRANSCRIBE_HELP')"
        @update:model-value="transcriptionEnabled = $event"
      />
    </div>
  </div>
</template>
