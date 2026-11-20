<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import CallSettingsOption from './CallSettingsOption.vue';
import CallMessagePlay from './CallMessagePlay.vue';
import CallBusinessHours from './CallBusinessHours.vue';

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

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.OUT_OF_HOURS.${key}`);

const hoursOn = computed(() => !!props.inbox.working_hours_enabled);

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
// The recording and saved text of whichever message callers hear outside business hours
const recording = computed(() =>
  sameAsMissed.value
    ? {
        url: props.inbox.unanswered_call_audio_url,
        savedText: props.inbox.unanswered_call_message || '',
      }
    : {
        url: props.inbox.out_of_hours_call_audio_url,
        savedText: props.inbox.out_of_hours_call_message || '',
      }
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <CallBusinessHours
      v-model="applyHours"
      :inbox="inbox"
      :help="label('APPLY_HELP')"
      @open-business-hours="emit('openBusinessHours')"
    />

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
          v-if="recording.url"
          :text="shownMessage"
          :audio-url="recording.url"
          :saved-text="recording.savedText"
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
