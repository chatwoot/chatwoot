<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'dashboard/components-next/select/Select.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import { durationOptions } from './callDurations';

// Who an incoming call rings, the same for Twilio and WhatsApp
const props = defineProps({
  inboxId: {
    type: Number,
    required: true,
  },
  // The interval the inbox saved, kept selectable when it is not a preset
  savedStepSeconds: {
    type: Number,
    default: null,
  },
});

const ringStrategy = defineModel('ringStrategy', { type: String });
const ringStepSeconds = defineModel('ringStepSeconds', { type: Number });
const assigneeRingsFirst = defineModel('assigneeRingsFirst', {
  type: Boolean,
});

// Within the 10–60 s interval the server accepts
const RING_STEP_PRESETS = [10, 15, 20, 30, 45, 60];
const SEQUENTIAL = 'sequential';

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.INCOMING.${key}`);
const stepOptions = computed(() =>
  durationOptions(t, RING_STEP_PRESETS, props.savedStepSeconds)
);
</script>

<template>
  <div class="flex flex-col gap-3">
    <span class="text-heading-3 text-n-slate-12">
      {{ label('WHO_RINGS') }}
    </span>
    <CallSettingsOption
      v-model="ringStrategy"
      value="simultaneous"
      :name="`call-ring-strategy-${inboxId}`"
      :label="label('SIMULTANEOUS')"
      :help="label('SIMULTANEOUS_HELP')"
    />
    <CallSettingsOption
      v-model="ringStrategy"
      :value="SEQUENTIAL"
      :name="`call-ring-strategy-${inboxId}`"
      :label="label('SEQUENTIAL')"
      :help="label('SEQUENTIAL_HELP')"
    />
    <label
      v-if="ringStrategy === SEQUENTIAL"
      class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
    >
      {{ label('STEP') }}
      <Select
        v-model="ringStepSeconds"
        :options="stepOptions"
        :aria-label="label('STEP')"
      />
    </label>
    <CallSettingsOption
      v-model="assigneeRingsFirst"
      :label="label('ASSIGNEE_FIRST')"
      :help="label('ASSIGNEE_FIRST_HELP')"
    />
    <p class="px-3 py-2 rounded-lg bg-n-teal-2 text-body-main text-n-slate-12">
      <span class="font-medium text-n-teal-11">{{ label('ALWAYS') }}</span>
      {{ label('ALWAYS_NOTE') }}
    </p>
  </div>
</template>
