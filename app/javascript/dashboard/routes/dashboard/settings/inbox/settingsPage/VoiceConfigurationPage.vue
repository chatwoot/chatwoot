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
import CallAfterCall from './calls/CallAfterCall.vue';
import TwilioCallConnection from './calls/TwilioCallConnection.vue';
import { durationOptions } from './calls/callDurations';
import {
  useCallSettingsForm,
  sharedSavedValues,
  sharedSteps,
} from './calls/useCallSettingsForm';

// The Calls tab of a Twilio inbox. Calling is turned on and its connection managed on their own;
// every other setting is saved together with Save changes.
const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const MESSAGE_MAX_LENGTH = 1000;
// Within the 10–300 s ring time the server accepts
const RING_TIME_PRESETS = [15, 30, 45, 60, 90, 120, 180, 300];

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
  <div
    class="flex flex-col divide-y outline outline-1 -outline-offset-1 outline-n-weak rounded-xl divide-n-weak"
  >
    <CallSettingsSection
      :title="label('CALLING.TITLE')"
      :description="label('CALLING.DESCRIPTION')"
    >
      <CallSettingsOption
        v-if="inbox.voice_enabled"
        v-model="form.inboundCallsEnabled"
        :label="label('CALLING.TAKE_INCOMING')"
        :help="label('CALLING.TAKE_INCOMING_HELP')"
      />
      <TwilioCallConnection :inbox="inbox" />
    </CallSettingsSection>

    <template v-if="inbox.voice_enabled">
      <div
        class="flex flex-col divide-y divide-n-weak"
        :class="{ 'pointer-events-none opacity-60': isSaving }"
      >
        <CallSettingsSection
          :title="label('INCOMING.TITLE')"
          :description="label('INCOMING.DESCRIPTION')"
        >
          <div class="flex flex-col gap-1.5">
            <label
              :for="`call-greeting-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('INCOMING.GREETING') }}
              <span class="text-n-slate-11">{{ label('OPTIONAL') }}</span>
            </label>
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
            <label
              :for="`call-missed-message-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('UNANSWERED.MESSAGE') }}
            </label>
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
          <CallSettingsOption
            v-model="form.businessHoursCallsEnabled"
            value
            :name="`call-out-of-hours-${inbox.id}`"
            :label="label('OUT_OF_HOURS.SAME_AS_UNANSWERED')"
            :help="label('OUT_OF_HOURS.SAME_AS_UNANSWERED_HELP')"
          />
          <CallSettingsOption
            v-model="form.businessHoursCallsEnabled"
            :value="false"
            :name="`call-out-of-hours-${inbox.id}`"
            :label="label('OUT_OF_HOURS.RING')"
          />
          <p
            v-if="
              form.businessHoursCallsEnabled && !inbox.working_hours_enabled
            "
            class="text-body-main text-n-amber-11"
          >
            {{ label('OUT_OF_HOURS.HOURS_OFF') }}
          </p>
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
      </div>

      <div class="flex justify-end px-5 py-4">
        <NextButton
          :label="label('SAVE')"
          :is-loading="isSaving"
          :disabled="!isDirty"
          @click="save"
        />
      </div>
    </template>
  </div>
</template>
