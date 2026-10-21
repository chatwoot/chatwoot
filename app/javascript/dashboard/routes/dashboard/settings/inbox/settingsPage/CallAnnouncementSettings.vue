<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  // The announcement this edits, as the API names it: 'out_of_hours' | 'greeting'
  kind: {
    type: String,
    required: true,
  },
  // The INBOX_MGMT.VOICE_CONFIGURATION block holding this announcement's copy
  i18nKey: {
    type: String,
    required: true,
  },
  enabled: {
    type: Boolean,
    default: false,
  },
  message: {
    type: String,
    default: '',
  },
  audioUrl: {
    type: String,
    default: '',
  },
  // The ring time saved with the no-answer announcement; null for announcements without one
  timeoutSeconds: {
    type: Number,
    default: null,
  },
});

const MESSAGE_MAX_LENGTH = 1000;
const TIMEOUT_SECONDS = { min: 10, max: 300 };
const store = useStore();
const { t } = useI18n();
const isEnabled = ref(props.enabled);
const draft = ref(props.message);
const timeout = ref(props.timeoutSeconds);
const isSaving = ref(false);
const hasTimeout = computed(() => props.timeoutSeconds !== null);
const isTimeoutValid = computed(() => {
  if (!hasTimeout.value) return true;
  const seconds = Number(timeout.value);
  return (
    Number.isInteger(seconds) &&
    seconds >= TIMEOUT_SECONDS.min &&
    seconds <= TIMEOUT_SECONDS.max
  );
});
const isDirty = computed(
  () =>
    draft.value.trim() !== props.message ||
    (hasTimeout.value && Number(timeout.value) !== props.timeoutSeconds)
);
// Unchanged text can be re-saved while its audio is missing, to generate it
const canSave = computed(
  () =>
    !isSaving.value &&
    !!draft.value.trim() &&
    isTimeoutValid.value &&
    (isDirty.value || !props.audioUrl)
);
const label = key =>
  t(`INBOX_MGMT.VOICE_CONFIGURATION.${props.i18nKey}.${key}`);

watch(
  [
    () => props.inbox.id,
    () => props.enabled,
    () => props.message,
    () => props.timeoutSeconds,
  ],
  ([, savedEnabled, savedMessage, savedTimeout]) => {
    isEnabled.value = savedEnabled;
    draft.value = savedMessage;
    timeout.value = savedTimeout;
  }
);

const save = async (nextEnabled = isEnabled.value, useDraft = true) => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateCallAnnouncement', {
      id: props.inbox.id,
      kind: props.kind,
      enabled: nextEnabled,
      message: useDraft ? draft.value.trim() : props.message,
      timeoutSeconds: hasTimeout.value
        ? Number(useDraft ? timeout.value : props.timeoutSeconds)
        : undefined,
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    isEnabled.value = props.enabled;
    useAlert(
      error?.response?.data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isSaving.value = false;
  }
};
const toggle = value => {
  isEnabled.value = value;
  if (value && !props.message) return;
  save(value, false);
};
</script>

<template>
  <div :class="{ 'pointer-events-none opacity-60': isSaving }">
    <SettingsToggleSection
      :model-value="isEnabled"
      :header="label('LABEL')"
      :description="label('DESCRIPTION')"
      @update:model-value="toggle"
    >
      <template v-if="isEnabled" #editor>
        <div class="flex flex-col gap-3">
          <slot name="notice" />
          <NextInput
            v-if="hasTimeout"
            :id="`call-announcement-${kind}-timeout-${inbox.id}`"
            v-model="timeout"
            type="number"
            :label="label('TIMEOUT.LABEL')"
            :message="label('TIMEOUT.HELP')"
            :min="String(TIMEOUT_SECONDS.min)"
            :max="String(TIMEOUT_SECONDS.max)"
            :disabled="isSaving"
            class="max-w-xs"
          />
          <TextArea
            :id="`call-announcement-${kind}-${inbox.id}`"
            v-model="draft"
            :label="label('MESSAGE.LABEL')"
            :placeholder="label('MESSAGE.PLACEHOLDER')"
            :max-length="MESSAGE_MAX_LENGTH"
            :disabled="isSaving"
            show-character-count
            auto-height
          />
          <p class="text-body-main text-n-slate-11">
            {{ $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.TWILIO_HELP') }}
          </p>
          <p v-if="message && !audioUrl" class="text-body-main text-n-slate-11">
            {{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.READ_BY_TWILIO')
            }}
          </p>
          <template v-if="audioUrl">
            <span class="text-body-main text-n-slate-12">{{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.ACTIVE')
            }}</span>
            <audio
              :key="audioUrl"
              :src="audioUrl"
              controls
              class="w-full"
              :aria-label="
                $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.ACTIVE')
              "
            />
          </template>
          <div>
            <NextButton
              :label="$t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.SAVE')"
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
