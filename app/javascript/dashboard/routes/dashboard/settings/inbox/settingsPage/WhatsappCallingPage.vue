<script setup>
import { ref, toRef, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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

// The Calls tab of a WhatsApp Cloud inbox. Turning calling on or off at Meta saves straight away;
// every other setting is saved together with Save changes, through the same endpoints as Twilio.
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

const savedValues = () => ({
  ...sharedSavedValues(props.inbox),
  permissionRequestBody:
    props.inbox.provider_config?.call_permission_request_body || '',
});

const buildSteps = (changed, values) => {
  const { id } = props.inbox;
  const steps = sharedSteps(id, changed, values);
  if (changed(['permissionRequestBody'])) {
    steps.push(() =>
      store.dispatch('inboxes/updateInbox', {
        id,
        formData: false,
        channel: {
          provider_config: {
            ...props.inbox.provider_config,
            call_permission_request_body:
              values.permissionRequestBody.trim() || null,
          },
        },
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
    await store.dispatch('inboxes/getItem', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (_) {
    callingEnabled.value = !value;
    useAlert(
      value
        ? t('INBOX_MGMT.WHATSAPP_CALLING.ENABLE_FAILED')
        : t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isTogglingCalling.value = false;
  }
};

const callHoursMatch = ref(null);
const isApplyingCallHours = ref(false);

const checkCallHours = async () => {
  callHoursMatch.value = null;
  const { id, business_hours_calls_enabled, working_hours_enabled } =
    props.inbox;
  const applied =
    callingEnabled.value &&
    business_hours_calls_enabled &&
    working_hours_enabled;
  if (!applied) return;
  try {
    const { data } = await InboxesAPI.getWhatsappCallHours(id);
    callHoursMatch.value = data.matches_whatsapp;
  } catch (_) {
    callHoursMatch.value = null;
  }
};

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
          :title="label('OUT_OF_HOURS.TITLE')"
          :description="label('OUT_OF_HOURS.DESCRIPTION')"
        >
          <CallBusinessHours
            v-model="form.businessHoursCallsEnabled"
            :inbox="inbox"
            :help="label('OUT_OF_HOURS.WHATSAPP_APPLY_HELP')"
            @open-business-hours="emit('openBusinessHours')"
          />
          <span
            v-if="callHoursMatch === true && form.businessHoursCallsEnabled"
            class="flex items-center gap-1.5 text-label-small text-n-teal-11"
          >
            <Icon icon="i-lucide-circle-check" class="size-3.5" />
            {{ label('OUT_OF_HOURS.WHATSAPP_HOURS_APPLIED') }}
          </span>
          <div
            v-else-if="
              callHoursMatch === false && form.businessHoursCallsEnabled
            "
            class="flex flex-col items-start gap-1 px-3 py-2 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-6 text-body-main text-n-slate-12"
          >
            {{ label('OUT_OF_HOURS.WHATSAPP_HOURS_DIFFER') }}
            <NextButton
              :label="label('OUT_OF_HOURS.WHATSAPP_APPLY_INBOX_HOURS')"
              :is-loading="isApplyingCallHours"
              link
              amber
              sm
              @click="applyInboxHours"
            />
          </div>
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
