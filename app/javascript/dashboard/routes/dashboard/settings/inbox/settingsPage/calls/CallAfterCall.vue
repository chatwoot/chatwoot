<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'dashboard/components-next/select/Select.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import { durationOptions } from './callDurations';

// Wrap-up time and what is kept from each call, the same for Twilio and WhatsApp
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
const WRAP_UP_PRESETS = [0, 30, 60, 120, 300, 600];

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.AFTER_CALL.${key}`);
const wrapUpOptions = computed(() =>
  durationOptions(t, WRAP_UP_PRESETS, props.savedCooldownSeconds)
);
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
    <CallSettingsOption v-model="recordingEnabled" :label="label('RECORD')" />
    <CallSettingsOption
      v-if="recordingEnabled"
      v-model="transcriptionEnabled"
      :label="label('TRANSCRIBE')"
      :help="label('TRANSCRIBE_HELP')"
    />
  </div>
</template>
