import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';

// The form behind a Calls tab, Twilio or WhatsApp. `savedValues` reads the inbox's saved settings,
// and `buildSteps(changed, values)` returns the requests for the groups that changed. Steps run one
// at a time, since each write merges into the same provider_config; the inbox is refetched after.
export const useCallSettingsForm = (inbox, savedValues, buildSteps) => {
  const store = useStore();
  const { t } = useI18n();
  const form = ref(savedValues());
  const isSaving = ref(false);

  watch(
    () => [inbox.value.id, JSON.stringify(savedValues())],
    () => {
      form.value = savedValues();
    }
  );

  const changed = keys => {
    const current = savedValues();
    return keys.some(key => form.value[key] !== current[key]);
  };
  const isDirty = computed(() => changed(Object.keys(form.value)));

  const save = async () => {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await buildSteps(changed, form.value).reduce(
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
      await store.dispatch('inboxes/get', inbox.value.id);
      isSaving.value = false;
    }
  };

  return { form, isSaving, isDirty, changed, save };
};

export const ROUTING_KEYS = [
  'ringStrategy',
  'ringStepSeconds',
  'assigneeRingsFirst',
  'callCooldownSeconds',
  'businessHoursCallsEnabled',
];

// The settings both providers save the same way
export const sharedSavedValues = inbox => ({
  inboundCallsEnabled: inbox.inbound_calls_enabled !== false,
  ringStrategy: inbox.ring_strategy,
  ringStepSeconds: inbox.ring_step_seconds,
  assigneeRingsFirst: inbox.assignee_rings_first !== false,
  businessHoursCallsEnabled: !!inbox.business_hours_calls_enabled,
  callCooldownSeconds: inbox.call_cooldown_seconds,
  recordingEnabled: inbox.recording_enabled !== false,
  transcriptionEnabled: inbox.transcription_enabled !== false,
});

export const sharedSteps = (id, changed, values) => {
  const steps = [];
  if (changed(['inboundCallsEnabled'])) {
    steps.push(() =>
      InboxesAPI.setInboundCalls(id, values.inboundCallsEnabled)
    );
  }
  if (changed(ROUTING_KEYS)) {
    steps.push(() => InboxesAPI.setCallRouting(id, values));
  }
  if (changed(['recordingEnabled', 'transcriptionEnabled'])) {
    steps.push(() => InboxesAPI.setCallRecording(id, values));
  }
  return steps;
};
