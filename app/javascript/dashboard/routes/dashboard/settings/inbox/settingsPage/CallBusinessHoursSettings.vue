<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
const isSaving = ref(false);
const isDirty = computed(
  () => message.value.trim() !== (props.inbox.out_of_hours_call_message || '')
);
const audioUrl = computed(() => props.inbox.out_of_hours_call_audio_url);
const canSave = computed(
  () =>
    !isSaving.value &&
    !!message.value.trim() &&
    (isDirty.value || !audioUrl.value)
);

watch(
  [
    () => props.inbox.id,
    () => !!props.inbox.business_hours_calls_enabled,
    () => props.inbox.out_of_hours_call_message || '',
  ],
  ([, savedEnabled, savedMessage]) => {
    enabled.value = !!savedEnabled;
    message.value = savedMessage || '';
  }
);

const showError = error =>
  useAlert(
    error?.response?.data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
  );
const save = async (nextEnabled = enabled.value, useDraft = true) => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateCallBusinessHours', {
      id: props.inbox.id,
      enabled: nextEnabled,
      message: useDraft
        ? message.value.trim()
        : props.inbox.out_of_hours_call_message || '',
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    enabled.value = !!props.inbox.business_hours_calls_enabled;
    showError(error);
  } finally {
    isSaving.value = false;
  }
};
const toggle = value => {
  enabled.value = value;
  if (value && !props.inbox.out_of_hours_call_message) return;
  save(value, false);
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
            :id="`out-of-hours-call-message-${inbox.id}`"
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
            :disabled="isSaving"
            show-character-count
            auto-height
          />
          <p class="text-body-main text-n-slate-11">
            {{
              $t(
                'INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.MESSAGE.TWILIO_HELP'
              )
            }}
          </p>
          <p
            v-if="inbox.out_of_hours_call_message && !audioUrl"
            class="text-body-main text-n-slate-11"
          >
            {{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.READ_BY_TWILIO')
            }}
          </p>
          <template v-if="audioUrl">
            <span class="text-body-main text-n-slate-12">{{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.ACTIVE')
            }}</span>
            <audio
              :key="audioUrl"
              :src="audioUrl"
              controls
              class="w-full"
              :aria-label="
                $t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.ACTIVE')
              "
            />
          </template>
          <div>
            <NextButton
              :label="$t('INBOX_MGMT.VOICE_CONFIGURATION.BUSINESS_HOURS.SAVE')"
              :is-loading="isSaving"
              :disabled="!canSave"
              @click="save()"
            />
          </div>
        </div>
      </template>
    </SettingsToggleSection>
  </div>
</template>
