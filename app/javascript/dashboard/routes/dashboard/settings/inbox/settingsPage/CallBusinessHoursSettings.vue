<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const MESSAGE_MAX_LENGTH = 1000;

const store = useStore();
const { t } = useI18n();

const enabled = ref(!!props.inbox.business_hours_calls_enabled);
const message = ref(props.inbox.out_of_hours_call_message || '');
const voicemail = ref(!!props.inbox.voicemail_enabled);
const isSaving = ref(false);

const isWhatsapp = computed(
  () => props.inbox.channel_type === INBOX_TYPES.WHATSAPP
);
const savedMessage = computed(() => props.inbox.out_of_hours_call_message);
const isMessageDirty = computed(
  () => message.value.trim() !== (savedMessage.value || '')
);
const isDirty = computed(
  () =>
    isMessageDirty.value || voicemail.value !== !!props.inbox.voicemail_enabled
);
// A voicemail is a call recording, so it follows the inbox's "Record calls" setting
const canTakeVoicemail = computed(
  () => props.inbox.recording_enabled !== false
);
const audioUrl = computed(() => props.inbox.out_of_hours_call_audio_url);
// Twilio reads the text itself when Captain couldn't record it
const isReadByTwilio = computed(
  () => !isWhatsapp.value && !!savedMessage.value && !audioUrl.value
);

watch(
  () => [
    props.inbox.business_hours_calls_enabled,
    props.inbox.out_of_hours_call_message,
    props.inbox.voicemail_enabled,
  ],
  ([savedEnabled, saved, savedVoicemail]) => {
    enabled.value = !!savedEnabled;
    message.value = saved || '';
    voicemail.value = !!savedVoicemail;
  }
);

const save = async nextEnabled => {
  if (isSaving.value) return;
  enabled.value = nextEnabled;
  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateCallBusinessHours', {
      id: props.inbox.id,
      enabled: nextEnabled,
      message: message.value,
      voicemail: voicemail.value,
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    enabled.value = !!props.inbox.business_hours_calls_enabled;
    useAlert(
      error?.response?.data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isSaving.value = false;
  }
};

// Turning it on without a saved message only opens the message field; saving the message turns it on.
const toggle = value => {
  if (value && !savedMessage.value) {
    enabled.value = true;
    return;
  }
  save(value);
};
</script>

<template>
  <div :class="{ 'pointer-events-none opacity-60': isSaving }">
    <SettingsToggleSection
      :model-value="enabled"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.LABEL')"
      :description="
        $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.DESCRIPTION')
      "
      @update:model-value="toggle"
    >
      <template v-if="enabled" #editor>
        <div class="flex flex-col gap-3">
          <p
            v-if="!inbox.working_hours_enabled"
            class="text-body-main text-n-amber-11"
          >
            {{
              $t(
                'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.HOURS_NOT_ENABLED'
              )
            }}
          </p>
          <TextArea
            v-model="message"
            :label="
              $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.MESSAGE.LABEL')
            "
            :placeholder="
              $t(
                'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.MESSAGE.PLACEHOLDER'
              )
            "
            :max-length="MESSAGE_MAX_LENGTH"
            show-character-count
            auto-height
          />
          <p class="text-body-main text-n-slate-11">
            {{
              isWhatsapp
                ? $t(
                    'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.MESSAGE.WHATSAPP_HELP'
                  )
                : $t(
                    'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.MESSAGE.TWILIO_HELP'
                  )
            }}
          </p>
          <audio
            v-if="audioUrl && !isMessageDirty"
            :key="audioUrl"
            :src="audioUrl"
            controls
            class="w-full"
          />
          <p
            v-else-if="isReadByTwilio && !isMessageDirty"
            class="text-body-main text-n-slate-11"
          >
            {{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.READ_BY_TWILIO')
            }}
          </p>
          <label
            v-if="!isWhatsapp"
            class="flex items-start gap-2"
            :class="{ 'opacity-60': !canTakeVoicemail }"
          >
            <Checkbox
              v-model="voicemail"
              :disabled="!canTakeVoicemail"
              class="mt-0.5"
            />
            <span class="flex flex-col gap-0.5">
              <span class="text-body-main text-n-slate-12">
                {{
                  $t(
                    'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.VOICEMAIL.LABEL'
                  )
                }}
              </span>
              <span class="text-body-main text-n-slate-11">
                {{
                  canTakeVoicemail
                    ? $t(
                        'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.VOICEMAIL.DESCRIPTION'
                      )
                    : $t(
                        'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.VOICEMAIL.NEEDS_RECORDING'
                      )
                }}
              </span>
            </span>
          </label>
          <div>
            <NextButton
              :label="
                isWhatsapp
                  ? $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.SAVE')
                  : $t(
                      'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.SAVE_AND_RECORD'
                    )
              "
              :is-loading="isSaving"
              :disabled="!isDirty || !message.trim()"
              @click="save(true)"
            />
          </div>
        </div>
      </template>
    </SettingsToggleSection>
  </div>
</template>
