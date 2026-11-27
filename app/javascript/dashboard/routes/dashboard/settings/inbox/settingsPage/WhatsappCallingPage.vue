<script setup>
import { computed, ref, toRef, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CallSettingsSection from './calls/CallSettingsSection.vue';
import CallSettingsOption from './calls/CallSettingsOption.vue';
import CallWhoRings from './calls/CallWhoRings.vue';
import CallAfterCall from './calls/CallAfterCall.vue';
import CallBusinessHours from './calls/CallBusinessHours.vue';
import {
  useCallSettingsForm,
  sharedSavedValues,
  sharedSteps,
} from './calls/useCallSettingsForm';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['openBusinessHours']);

const store = useStore();
const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.${key}`);

const MESSAGE_MAX_LENGTH = 1000;
const PROVIDER_CONFIG_KEYS = [
  'permissionRequestBody',
  'missedCallMessageEnabled',
  'missedCallMessage',
];

const savedValues = () => ({
  ...sharedSavedValues(props.inbox),
  permissionRequestBody:
    props.inbox.provider_config?.call_permission_request_body || '',
  missedCallMessageEnabled:
    props.inbox.provider_config?.missed_call_message_enabled === true,
  missedCallMessage: props.inbox.provider_config?.missed_call_message || '',
  callbackPermissionEnabled:
    props.inbox.provider_config?.callback_permission_enabled === true,
});

const buildSteps = (changed, values) => {
  const { id } = props.inbox;
  const steps = [];
  if (changed(PROVIDER_CONFIG_KEYS)) {
    steps.push(() =>
      store.dispatch('inboxes/updateInbox', {
        id,
        formData: false,
        channel: {
          provider_config: {
            ...props.inbox.provider_config,
            call_permission_request_body:
              values.permissionRequestBody.trim() || null,
            missed_call_message_enabled: values.missedCallMessageEnabled,
            missed_call_message: values.missedCallMessage.trim() || null,
          },
        },
      })
    );
  }
  // After the save above, which writes back the whole provider_config it was given
  if (changed(['callbackPermissionEnabled'])) {
    steps.push(() =>
      InboxesAPI.setWhatsappCallbackPermission(
        id,
        values.callbackPermissionEnabled
      )
    );
  }
  return [...steps, ...sharedSteps(id, changed, values)];
};

const { form, isSaving, isDirty, save } = useCallSettingsForm(
  toRef(props, 'inbox'),
  savedValues,
  buildSteps
);

const callingEnabled = ref(!!props.inbox.provider_config?.calling_enabled);
const isTogglingCalling = ref(false);
watch(
  () => props.inbox.provider_config?.calling_enabled,
  value => {
    callingEnabled.value = !!value;
  }
);

const toggleCalling = async value => {
  if (isTogglingCalling.value) return;
  callingEnabled.value = value;
  isTogglingCalling.value = true;
  try {
    if (value) {
      await InboxesAPI.enableWhatsappCalling(props.inbox.id);
    } else {
      await InboxesAPI.disableWhatsappCalling(props.inbox.id);
    }
    await store.dispatch('inboxes/getItem', props.inbox.id).catch(() => {});
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    callingEnabled.value = !value;
    const hoursError = error?.response?.data?.message;
    useAlert(
      value
        ? hoursError || t('INBOX_MGMT.WHATSAPP_CALLING.ENABLE_FAILED')
        : t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isTogglingCalling.value = false;
  }
};

const callHoursMatch = ref(null);
const isCheckingCallHours = ref(false);
const isApplyingCallHours = ref(false);

const callHoursApplied = computed(
  () =>
    !!props.inbox.business_hours_calls_enabled &&
    !!props.inbox.working_hours_enabled
);

const checkCallHours = async () => {
  callHoursMatch.value = null;
  if (!callingEnabled.value) return;
  isCheckingCallHours.value = true;
  try {
    const { data } = await InboxesAPI.getWhatsappCallHours(props.inbox.id);
    callHoursMatch.value = data.matches_whatsapp;
  } catch (_) {
    callHoursMatch.value = null;
  } finally {
    isCheckingCallHours.value = false;
  }
};

const isSavingCallHours = computed(
  () =>
    isApplyingCallHours.value ||
    (isSaving.value &&
      form.value.businessHoursCallsEnabled !==
        !!props.inbox.business_hours_calls_enabled)
);

watch(
  () => [
    callingEnabled.value,
    props.inbox.business_hours_calls_enabled,
    props.inbox.working_hours_enabled,
  ],
  checkCallHours,
  { immediate: true }
);

const applyInboxHours = async () => {
  if (isApplyingCallHours.value) return;
  isApplyingCallHours.value = true;
  try {
    await InboxesAPI.applyWhatsappCallHours(props.inbox.id);
    callHoursMatch.value = true;
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isApplyingCallHours.value = false;
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
      <div
        class="flex flex-col gap-4"
        :class="{ 'pointer-events-none opacity-60': isTogglingCalling }"
      >
        <CallSettingsOption
          v-if="!callingEnabled"
          :model-value="false"
          :label="label('CALLING.WHATSAPP_ENABLE')"
          :help="label('CALLING.WHATSAPP_ENABLE_HELP')"
          @update:model-value="toggleCalling"
        />
        <template v-else>
          <CallSettingsOption
            v-model="form.inboundCallsEnabled"
            :label="label('CALLING.TAKE_INCOMING')"
            :help="label('CALLING.TAKE_INCOMING_HELP')"
          />
          <div class="flex flex-wrap items-center gap-2 text-body-main">
            <span
              class="px-2 py-0.5 rounded-md bg-n-teal-3 text-n-teal-11 font-mono text-sm"
            >
              {{ label('CALLING.META_ON') }}
            </span>
            <span class="text-n-slate-12">{{
              label('CALLING.META_HELP')
            }}</span>
            <NextButton
              :label="label('CALLING.TURN_OFF')"
              link
              ruby
              sm
              @click="toggleCalling(false)"
            />
          </div>
        </template>
      </div>
    </CallSettingsSection>

    <template v-if="callingEnabled">
      <div
        class="flex flex-col divide-y divide-n-weak"
        :class="{ 'pointer-events-none opacity-60': isSaving }"
      >
        <CallSettingsSection
          :title="label('INCOMING.TITLE')"
          :description="label('INCOMING.WHATSAPP_DESCRIPTION')"
        >
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
          :description="label('UNANSWERED.WHATSAPP_DESCRIPTION')"
        >
          <CallSettingsOption
            v-model="form.missedCallMessageEnabled"
            :label="label('UNANSWERED.WHATSAPP_SEND')"
            :help="label('UNANSWERED.WHATSAPP_SEND_HELP')"
          />
          <div
            v-if="form.missedCallMessageEnabled"
            class="flex flex-col gap-1.5"
          >
            <label
              :for="`call-missed-message-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('UNANSWERED.MESSAGE') }}
            </label>
            <TextArea
              :id="`call-missed-message-${inbox.id}`"
              v-model="form.missedCallMessage"
              :placeholder="label('UNANSWERED.WHATSAPP_PLACEHOLDER')"
              :max-length="MESSAGE_MAX_LENGTH"
              show-character-count
              auto-height
            />
            <p class="text-body-main text-n-slate-11">
              {{ label('UNANSWERED.WHATSAPP_MESSAGE_HELP') }}
            </p>
          </div>
        </CallSettingsSection>

        <CallSettingsSection
          :title="label('OUT_OF_HOURS.TITLE')"
          :description="label('OUT_OF_HOURS.DESCRIPTION')"
        >
          <CallBusinessHours
            v-model="form.businessHoursCallsEnabled"
            :inbox="inbox"
            :help="label('OUT_OF_HOURS.WHATSAPP_APPLY_HELP')"
            @open-business-hours="emit('openBusinessHours')"
          />
          <div
            v-if="callHoursMatch === false && !callHoursApplied"
            class="flex flex-col items-start gap-1 px-3 py-2 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-6 text-body-main text-n-slate-12"
          >
            {{ label('OUT_OF_HOURS.WHATSAPP_HOURS_STILL_ON') }}
            <NextButton
              :label="label('OUT_OF_HOURS.WHATSAPP_TURN_OFF_HOURS')"
              :is-loading="isApplyingCallHours"
              link
              amber
              sm
              @click="applyInboxHours"
            />
          </div>
          <template v-else-if="form.businessHoursCallsEnabled">
            <span
              v-if="isSavingCallHours || isCheckingCallHours"
              class="flex items-center gap-1.5 text-label-small text-n-slate-11"
            >
              <Spinner class="size-3.5" />
              {{
                isSavingCallHours
                  ? label('OUT_OF_HOURS.WHATSAPP_HOURS_APPLYING')
                  : label('OUT_OF_HOURS.WHATSAPP_HOURS_CHECKING')
              }}
            </span>
            <span
              v-else-if="callHoursMatch === true"
              class="flex items-center gap-1.5 text-label-small text-n-teal-11"
            >
              <Icon icon="i-lucide-circle-check" class="size-3.5" />
              {{ label('OUT_OF_HOURS.WHATSAPP_HOURS_APPLIED') }}
            </span>
            <div
              v-else-if="callHoursMatch === false"
              class="flex flex-col items-start gap-1 px-3 py-2 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-6 text-body-main text-n-slate-12"
            >
              {{ label('OUT_OF_HOURS.WHATSAPP_HOURS_DIFFER') }}
              <NextButton
                :label="label('OUT_OF_HOURS.WHATSAPP_APPLY_INBOX_HOURS')"
                link
                amber
                sm
                @click="applyInboxHours"
              />
            </div>
          </template>
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

        <CallSettingsSection
          :title="label('CALLING_CUSTOMERS.TITLE')"
          :description="label('CALLING_CUSTOMERS.DESCRIPTION')"
        >
          <CallSettingsOption
            v-model="form.callbackPermissionEnabled"
            :label="label('CALLING_CUSTOMERS.CALLBACK_PERMISSION')"
            :help="label('CALLING_CUSTOMERS.CALLBACK_PERMISSION_HELP')"
          />
          <div class="flex flex-col gap-1.5">
            <label
              :for="`call-permission-request-${inbox.id}`"
              class="mb-0 text-heading-3 text-n-slate-12"
            >
              {{ label('CALLING_CUSTOMERS.PERMISSION_MESSAGE') }}
            </label>
            <TextArea
              :id="`call-permission-request-${inbox.id}`"
              v-model="form.permissionRequestBody"
              :placeholder="label('CALLING_CUSTOMERS.PERMISSION_PLACEHOLDER')"
              auto-height
            />
            <p class="text-body-main text-n-slate-11">
              {{ label('CALLING_CUSTOMERS.PERMISSION_HELP') }}
            </p>
          </div>
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
