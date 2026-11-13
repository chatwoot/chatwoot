<script setup>
import { ref, toRef, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CallSettingsSection from './calls/CallSettingsSection.vue';
import CallSettingsOption from './calls/CallSettingsOption.vue';
import CallWhoRings from './calls/CallWhoRings.vue';
import CallAfterCall from './calls/CallAfterCall.vue';
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

const store = useStore();
const { t } = useI18n();
const label = key => t(`INBOX_MGMT.CALL_SETTINGS.${key}`);

const savedValues = () => ({
  ...sharedSavedValues(props.inbox),
  callbackPermissionEnabled: !!props.inbox.callback_permission_enabled,
  permissionRequestBody:
    props.inbox.provider_config?.call_permission_request_body || '',
});

const buildSteps = (changed, values) => {
  const { id } = props.inbox;
  const steps = sharedSteps(id, changed, values);
  if (changed(['callbackPermissionEnabled'])) {
    steps.push(() =>
      InboxesAPI.setCallbackPermission(id, values.callbackPermissionEnabled)
    );
  }
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
    await store.dispatch('inboxes/get', props.inbox.id);
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
          <CallSettingsOption
            v-model="form.businessHoursCallsEnabled"
            value
            :name="`call-out-of-hours-${inbox.id}`"
            :label="label('OUT_OF_HOURS.DECLINE')"
            :help="label('OUT_OF_HOURS.DECLINE_HELP')"
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

        <CallSettingsSection
          :title="label('CALLING_CUSTOMERS.TITLE')"
          :description="label('CALLING_CUSTOMERS.DESCRIPTION')"
        >
          <CallSettingsOption
            v-model="form.callbackPermissionEnabled"
            :label="label('CALLING_CUSTOMERS.CALLBACK')"
            :help="label('CALLING_CUSTOMERS.CALLBACK_HELP')"
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
