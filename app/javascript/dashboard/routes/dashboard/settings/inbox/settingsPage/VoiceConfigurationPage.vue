<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CallSettingsSection from './calls/CallSettingsSection.vue';
import CallSettingsOption from './calls/CallSettingsOption.vue';
import TwilioCallConnection from './calls/TwilioCallConnection.vue';
import { durationOptions } from './calls/callDurations';

// The Calls tab of a Twilio inbox. Calling is turned on and its connection managed on their own;
// every other setting is saved together with Save changes.
const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const MESSAGE_MAX_LENGTH = 1000;
// Within the bounds the server accepts: 10–60 s interval, 10–300 s ring time, 0–600 s wrap-up
const RING_STEP_PRESETS = [10, 15, 20, 30, 45, 60];
const RING_TIME_PRESETS = [15, 30, 45, 60, 90, 120, 180, 300];
const WRAP_UP_PRESETS = [0, 30, 60, 120, 300, 600];
const SEQUENTIAL = 'sequential';

const store = useStore();
const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.${key}`);

// A greeting switched off keeps its text on the server; the empty box is what turns it off here
const saved = () => ({
  inboundCallsEnabled: props.inbox.inbound_calls_enabled !== false,
  greeting: props.inbox.call_greeting_enabled
    ? props.inbox.call_greeting_message || ''
    : '',
  ringStrategy: props.inbox.ring_strategy,
  ringStepSeconds: props.inbox.ring_step_seconds,
  assigneeRingsFirst: props.inbox.assignee_rings_first !== false,
  ringTimeSeconds: props.inbox.unanswered_call_timeout_seconds,
  missedCallMessage: props.inbox.unanswered_call_message || '',
  businessHoursCallsEnabled: !!props.inbox.business_hours_calls_enabled,
  callCooldownSeconds: props.inbox.call_cooldown_seconds,
  recordingEnabled: props.inbox.recording_enabled !== false,
  transcriptionEnabled: props.inbox.transcription_enabled !== false,
});
const form = ref(saved());
const isSaving = ref(false);

watch(
  () => [props.inbox.id, JSON.stringify(saved())],
  () => {
    form.value = saved();
  }
);

const changed = keys => {
  const current = saved();
  return keys.some(key => form.value[key] !== current[key]);
};
const greetingChanged = () => form.value.greeting.trim() !== saved().greeting;
const isDirty = computed(
  () =>
    greetingChanged() ||
    changed(Object.keys(form.value).filter(key => key !== 'greeting'))
);

const ringStepOptions = computed(() =>
  durationOptions(t, RING_STEP_PRESETS, props.inbox.ring_step_seconds)
);
const ringTimeOptions = computed(() =>
  durationOptions(
    t,
    RING_TIME_PRESETS,
    props.inbox.unanswered_call_timeout_seconds
  )
);
const wrapUpOptions = computed(() =>
  durationOptions(t, WRAP_UP_PRESETS, props.inbox.call_cooldown_seconds)
);

// Each group goes to the endpoint that owns it, and only when something in it changed
const saveSteps = () => {
  const { id } = props.inbox;
  const values = form.value;
  const steps = [];
  if (changed(['inboundCallsEnabled'])) {
    steps.push(() =>
      InboxesAPI.setInboundCalls(id, values.inboundCallsEnabled)
    );
  }
  if (greetingChanged()) {
    const message = values.greeting.trim();
    steps.push(() =>
      InboxesAPI.setCallAnnouncement(id, 'greeting', {
        enabled: !!message,
        message,
      })
    );
  }
  if (
    changed([
      'ringStrategy',
      'ringStepSeconds',
      'assigneeRingsFirst',
      'callCooldownSeconds',
      'businessHoursCallsEnabled',
    ])
  ) {
    steps.push(() => InboxesAPI.setCallRouting(id, values));
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
  if (changed(['recordingEnabled', 'transcriptionEnabled'])) {
    steps.push(() => InboxesAPI.setCallRecording(id, values));
  }
  return steps;
};

const save = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    // One at a time, since each write merges into the same provider_config
    await saveSteps().reduce(
      (previous, step) => previous.then(step),
      Promise.resolve()
    );
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const { data } = error?.response || {};
    useAlert(
      data?.message || data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    await store.dispatch('inboxes/get', props.inbox.id);
    isSaving.value = false;
  }
};
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

          <div class="flex flex-col gap-3">
            <span class="text-heading-3 text-n-slate-12">
              {{ label('INCOMING.WHO_RINGS') }}
            </span>
            <CallSettingsOption
              v-model="form.ringStrategy"
              value="simultaneous"
              :name="`call-ring-strategy-${inbox.id}`"
              :label="label('INCOMING.SIMULTANEOUS')"
              :help="label('INCOMING.SIMULTANEOUS_HELP')"
            />
            <CallSettingsOption
              v-model="form.ringStrategy"
              :value="SEQUENTIAL"
              :name="`call-ring-strategy-${inbox.id}`"
              :label="label('INCOMING.SEQUENTIAL')"
              :help="label('INCOMING.SEQUENTIAL_HELP')"
            />
            <label
              v-if="form.ringStrategy === SEQUENTIAL"
              class="flex items-center gap-2 mb-0 ps-7 text-body-main text-n-slate-12"
            >
              {{ label('INCOMING.STEP') }}
              <Select
                v-model="form.ringStepSeconds"
                :options="ringStepOptions"
                :aria-label="label('INCOMING.STEP')"
              />
            </label>
            <CallSettingsOption
              v-model="form.assigneeRingsFirst"
              :label="label('INCOMING.ASSIGNEE_FIRST')"
              :help="label('INCOMING.ASSIGNEE_FIRST_HELP')"
            />
          </div>

          <p
            class="px-3 py-2 rounded-lg bg-n-teal-2 text-body-main text-n-slate-12"
          >
            <span class="font-medium text-n-teal-11">
              {{ label('INCOMING.ALWAYS') }}
            </span>
            {{ label('INCOMING.ALWAYS_NOTE') }}
          </p>
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
          <div class="flex flex-col gap-1.5">
            <label
              class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
            >
              {{ label('AFTER_CALL.WRAP_UP') }}
              <Select
                v-model="form.callCooldownSeconds"
                :options="wrapUpOptions"
                :aria-label="label('AFTER_CALL.WRAP_UP')"
              />
            </label>
            <p class="text-body-main text-n-slate-11">
              {{ label('AFTER_CALL.WRAP_UP_HELP') }}
            </p>
          </div>
          <CallSettingsOption
            v-model="form.recordingEnabled"
            :label="label('AFTER_CALL.RECORD')"
            :help="label('AFTER_CALL.RECORD_HELP')"
          />
          <CallSettingsOption
            v-if="form.recordingEnabled"
            v-model="form.transcriptionEnabled"
            :label="label('AFTER_CALL.TRANSCRIBE')"
            :help="label('AFTER_CALL.TRANSCRIBE_HELP')"
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
