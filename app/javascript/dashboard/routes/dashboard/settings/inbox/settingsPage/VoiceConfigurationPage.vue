<script setup>
import { computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import InboxesAPI from 'dashboard/api/inboxes';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CallSettingsSection from './calls/CallSettingsSection.vue';
import CallSettingsOption from './calls/CallSettingsOption.vue';
import CallWhoRings from './calls/CallWhoRings.vue';
import CallOutOfHours from './calls/CallOutOfHours.vue';
import CallAfterCall from './calls/CallAfterCall.vue';
import CallMessagePlay from './calls/CallMessagePlay.vue';
import TwilioCallingCard from './calls/TwilioCallingCard.vue';
import { durationOptions } from './calls/callDurations';
import {
  useCallSettingsForm,
  sharedSavedValues,
  sharedSteps,
} from './calls/useCallSettingsForm';

// The Calls tab of a Twilio inbox. Calling is turned on and off, and its connection managed, on
// their own; every other setting is saved together with Save changes. While calling is off the rest
// of the page is greyed out.
const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['openBusinessHours']);

const MESSAGE_MAX_LENGTH = 1000;
// Within the 10–300 s ring time the server accepts
const RING_TIME_PRESETS = [30, 60, 120, 300];

const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.${key}`);

// A greeting switched off keeps its text on the server; the empty box is what turns it off here
const savedValues = () => ({
  ...sharedSavedValues(props.inbox),
  greeting: props.inbox.call_greeting_enabled
    ? props.inbox.call_greeting_message || ''
    : '',
  ringTimeSeconds: props.inbox.unanswered_call_timeout_seconds,
  missedCallMessage: props.inbox.unanswered_call_message || '',
  outOfHoursMessage: props.inbox.out_of_hours_call_message || '',
});

const buildSteps = (changed, values) => {
  const { id } = props.inbox;
  const steps = sharedSteps(id, changed, values);
  if (changed(['greeting'])) {
    const message = values.greeting.trim();
    steps.push(() =>
      InboxesAPI.setCallAnnouncement(id, 'greeting', {
        enabled: !!message,
        message,
      })
    );
  }
  if (changed(['ringTimeSeconds', 'missedCallMessage'])) {
    steps.push(() =>
      InboxesAPI.setCallAnnouncement(id, 'unanswered', {
        enabled: true,
        message: values.missedCallMessage.trim(),
        timeoutSeconds: values.ringTimeSeconds,
      })
    );
  }
  if (changed(['outOfHoursMessage'])) {
    steps.push(() =>
      InboxesAPI.setCallAnnouncement(id, 'out_of_hours', {
        enabled: true,
        message: values.outOfHoursMessage.trim(),
      })
    );
  }
  return steps;
};

const { form, isSaving, isDirty, save } = useCallSettingsForm(
  toRef(props, 'inbox'),
  savedValues,
  buildSteps
);

const ringTimeOptions = computed(() =>
  durationOptions(
    t,
    RING_TIME_PRESETS,
    props.inbox.unanswered_call_timeout_seconds
  )
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <TwilioCallingCard :inbox="inbox">
      <CallSettingsOption
        v-model="form.inboundCallsEnabled"
        :label="label('CALLING.TAKE_INCOMING')"
        :help="label('CALLING.TAKE_INCOMING_HELP')"
      />
    </TwilioCallingCard>

    <div
      class="flex flex-col divide-y outline outline-1 -outline-offset-1 outline-n-weak rounded-xl divide-n-weak"
      :class="{
        'pointer-events-none opacity-50': isSaving || !inbox.voice_enabled,
      }"
    >
      <CallSettingsSection
        :title="label('INCOMING.TITLE')"
        :description="label('INCOMING.DESCRIPTION')"
      >
        <div class="flex flex-col gap-1.5">
          <div class="flex items-center justify-between gap-2">
            <label
              :for="`call-greeting-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('INCOMING.GREETING') }}
              <span class="text-n-slate-11">{{ label('OPTIONAL') }}</span>
            </label>
            <CallMessagePlay
              :text="form.greeting"
              :audio-url="inbox.call_greeting_audio_url || ''"
              :saved-text="inbox.call_greeting_message || ''"
            />
          </div>
          <TextArea
            :id="`call-greeting-${inbox.id}`"
            v-model="form.greeting"
            :placeholder="label('INCOMING.GREETING_PLACEHOLDER')"
            :max-length="MESSAGE_MAX_LENGTH"
            auto-height
          />
          <p class="text-body-main text-n-slate-11">
            {{ label('INCOMING.GREETING_HELP') }}
          </p>
        </div>
        <CallWhoRings
          v-model:ring-strategy="form.ringStrategy"
          v-model:ring-step-seconds="form.ringStepSeconds"
          v-model:assignee-rings-first="form.assigneeRingsFirst"
          :inbox-id="inbox.id"
          :saved-step-seconds="inbox.ring_step_seconds"
        />
      </CallSettingsSection>

      <CallSettingsSection
        :title="label('UNANSWERED.TITLE')"
        :description="label('UNANSWERED.DESCRIPTION')"
      >
        <label
          class="flex flex-wrap items-center gap-2 mb-0 text-body-main text-n-slate-12"
        >
          {{ label('UNANSWERED.WAIT') }}
          <Select
            v-model="form.ringTimeSeconds"
            :options="ringTimeOptions"
            :aria-label="label('UNANSWERED.WAIT')"
          />
          {{ label('UNANSWERED.THEN') }}
        </label>
        <div class="flex flex-col gap-1.5">
          <div class="flex items-center justify-between gap-2">
            <label
              :for="`call-missed-message-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('UNANSWERED.MESSAGE') }}
            </label>
            <CallMessagePlay
              :text="form.missedCallMessage"
              :audio-url="inbox.unanswered_call_audio_url || ''"
              :saved-text="inbox.unanswered_call_message || ''"
            />
          </div>
          <TextArea
            :id="`call-missed-message-${inbox.id}`"
            v-model="form.missedCallMessage"
            :max-length="MESSAGE_MAX_LENGTH"
            auto-height
          />
          <p class="text-body-main text-n-slate-11">
            {{ label('UNANSWERED.MESSAGE_HELP') }}
          </p>
        </div>
      </CallSettingsSection>

      <CallSettingsSection
        :title="label('OUT_OF_HOURS.TITLE')"
        :description="label('OUT_OF_HOURS.DESCRIPTION')"
      >
        <CallOutOfHours
          v-model:apply-hours="form.businessHoursCallsEnabled"
          v-model:message="form.outOfHoursMessage"
          :inbox="inbox"
          :missed-call-message="form.missedCallMessage"
          :max-length="MESSAGE_MAX_LENGTH"
          @open-business-hours="emit('openBusinessHours')"
        />
      </CallSettingsSection>

      <CallSettingsSection
        :title="label('AFTER_CALL.TITLE')"
        :description="label('AFTER_CALL.DESCRIPTION')"
      >
        <CallAfterCall
          v-model:call-cooldown-seconds="form.callCooldownSeconds"
          v-model:recording-enabled="form.recordingEnabled"
          v-model:transcription-enabled="form.transcriptionEnabled"
          :saved-cooldown-seconds="inbox.call_cooldown_seconds"
        />
      </CallSettingsSection>

      <div class="flex justify-end px-5 py-4">
        <NextButton
          :label="label('SAVE')"
          :is-loading="isSaving"
          :disabled="!isDirty || !inbox.voice_enabled"
          @click="save"
        />
      </div>
    </div>
  </div>
</template>
