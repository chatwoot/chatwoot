<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'dashboard/components-next/select/Select.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import { durationOptions } from './callDurations';

// How an incoming call is routed to agents
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
const RING_STEP_PRESETS = [10, 20, 30];
const SEQUENTIAL = 'sequential';

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.INCOMING.${key}`);
const strategies = computed(() => [
  {
    id: 'simultaneous',
    label: label('SIMULTANEOUS'),
    description: label('SIMULTANEOUS_HELP'),
  },
  {
    id: SEQUENTIAL,
    label: label('SEQUENTIAL'),
    description: label('SEQUENTIAL_HELP'),
  },
]);
const stepOptions = computed(() =>
  durationOptions(t, RING_STEP_PRESETS, props.savedStepSeconds)
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col gap-3">
      <span class="text-heading-3 text-n-slate-12">
        {{ label('ROUTING') }}
      </span>
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <RadioCard
          v-for="strategy in strategies"
          :id="`call-routing-${strategy.id}-${inboxId}`"
          :key="strategy.id"
          :name="`call-routing-strategy-${inboxId}`"
          :label="strategy.label"
          :description="strategy.description"
          :is-active="ringStrategy === strategy.id"
          @select="ringStrategy = strategy.id"
        />
      </div>
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
    </div>
    <CallSettingsOption
      v-model="assigneeRingsFirst"
      card
      :label="label('ASSIGNEE_FIRST')"
      :help="label('ASSIGNEE_FIRST_HELP')"
    />
    <p class="px-3 py-2 rounded-lg bg-n-teal-2 text-body-main text-n-slate-12">
      <span class="font-medium text-n-teal-11">{{ label('ALWAYS') }}</span>
      {{ label('ALWAYS_NOTE') }}
    </p>
  </div>
</template>
