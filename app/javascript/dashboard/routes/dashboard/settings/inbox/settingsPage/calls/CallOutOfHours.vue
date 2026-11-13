<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import CallMessagePlay from './CallMessagePlay.vue';
import { businessHoursSummary } from './businessHours';

// Whether calls follow the inbox's business hours, and what a caller hears outside them. An empty
// out-of-hours message is the missed-call message.
const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  missedCallMessage: {
    type: String,
    default: '',
  },
  maxLength: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['openBusinessHours']);

const applyHours = defineModel('applyHours', { type: Boolean });
const message = defineModel('message', { type: String });

const { t, locale } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.OUT_OF_HOURS.${key}`);

const hoursOn = computed(() => !!props.inbox.working_hours_enabled);
const hoursSummary = computed(() =>
  businessHoursSummary(props.inbox.working_hours, {
    locale: locale.value,
    allDayLabel: label('ALL_DAY'),
  })
);

// Ticked while the message is empty; unticking starts the text from the missed-call message
const sameAsMissed = computed({
  get: () => message.value === '',
  set: same => {
    message.value = same ? '' : props.missedCallMessage;
  },
});
const shownMessage = computed(() =>
  sameAsMissed.value ? props.missedCallMessage : message.value
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between gap-4">
      <span class="flex flex-col gap-0.5">
        <span class="text-body-main font-medium text-n-slate-12">
          {{ label('APPLY') }}
        </span>
        <span class="text-body-main text-n-slate-11">
          {{ label('APPLY_HELP') }}
        </span>
      </span>
      <ToggleSwitch v-model="applyHours" />
    </div>

    <div
      v-if="!hoursOn"
      class="flex flex-col items-start gap-1 px-3 py-2 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-6 text-body-main text-n-slate-12"
    >
      {{ applyHours ? label('HOURS_OFF_APPLIED') : label('HOURS_OFF') }}
      <NextButton
        :label="label('GO_TO_HOURS')"
        link
        amber
        sm
        @click="emit('openBusinessHours')"
      />
    </div>
    <div
      v-else-if="applyHours"
      class="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-2 rounded-lg bg-n-alpha-black2 text-body-main text-n-slate-12"
    >
      <span>
        <span class="font-medium">{{ label('INBOX_HOURS') }}</span>
        {{ hoursSummary || label('ALWAYS_CLOSED') }} · {{ inbox.timezone }}
      </span>
      <NextButton
        :label="label('EDIT_HOURS')"
        link
        sm
        @click="emit('openBusinessHours')"
      />
    </div>

    <div
      v-if="applyHours"
      class="flex flex-col gap-1.5"
      :class="{ 'pointer-events-none opacity-50': !hoursOn }"
    >
      <div class="flex items-center justify-between gap-2">
        <label
          :for="`call-out-of-hours-message-${inbox.id}`"
          class="mb-0 text-heading-3 text-n-slate-12"
        >
          {{ label('MESSAGE') }}
        </label>
        <CallMessagePlay
          :text="shownMessage"
          :audio-url="
            sameAsMissed
              ? inbox.unanswered_call_audio_url || ''
              : inbox.out_of_hours_call_audio_url || ''
          "
          :saved-text="
            sameAsMissed
              ? inbox.unanswered_call_message || ''
              : inbox.out_of_hours_call_message || ''
          "
        />
      </div>
      <TextArea
        :id="`call-out-of-hours-message-${inbox.id}`"
        :model-value="shownMessage"
        :max-length="maxLength"
        :disabled="sameAsMissed"
        auto-height
        @update:model-value="message = $event"
      />
      <CallSettingsOption v-model="sameAsMissed" :label="label('SAME')" />
      <p class="text-body-main text-n-slate-11">
        {{ label('MESSAGE_HELP') }}
      </p>
    </div>
  </div>
</template>
