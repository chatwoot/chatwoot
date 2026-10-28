<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsCheckboxOption from './SettingsCheckboxOption.vue';

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
  // The saved recording of an announcement Captain records (out of hours); null for text-only ones
  audioUrl: {
    type: String,
    default: null,
  },
  // The ring time saved with the no-answer announcement; null for announcements without one
  timeoutSeconds: {
    type: Number,
    default: null,
  },
  // Renders a one-line checkbox instead of a toggle card
  checkbox: {
    type: Boolean,
    default: false,
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
const isDirty = computed(
  () =>
    draft.value.trim() !== props.message ||
    (hasTimeout.value && Number(timeout.value) !== props.timeoutSeconds)
);
const recordsAudio = computed(() => props.audioUrl !== null);
// Unchanged text can be re-saved while its audio is missing, to generate it
const canSave = computed(
  () =>
    !isSaving.value &&
    !!draft.value.trim() &&
    (isDirty.value || (recordsAudio.value && !props.audioUrl))
);
const label = key =>
  t(`INBOX_MGMT.VOICE_CONFIGURATION.${props.i18nKey}.${key}`);
const shell = computed(() =>
  props.checkbox
    ? { header: label('LABEL') }
    : { header: label('LABEL'), description: label('DESCRIPTION') }
);

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
    <component
      :is="checkbox ? SettingsCheckboxOption : SettingsToggleSection"
      v-bind="shell"
      :model-value="isEnabled"
      @update:model-value="toggle"
    >
      <template v-if="isEnabled" #editor>
        <div class="flex flex-col gap-3" :class="{ 'pt-1': !checkbox }">
          <slot name="notice" />
          <TextArea
            :id="`call-announcement-${kind}-${inbox.id}`"
            v-model="draft"
            :placeholder="label('PLACEHOLDER')"
            :max-length="MESSAGE_MAX_LENGTH"
            :disabled="isSaving"
            show-character-count
            auto-height
          />
          <template v-if="recordsAudio">
            <p class="text-body-main text-n-slate-11">
              {{
                $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.TWILIO_HELP')
              }}
            </p>
            <p
              v-if="message && !audioUrl"
              class="text-body-main text-n-slate-11"
            >
              {{
                $t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.READ_BY_TWILIO')
              }}
            </p>
          </template>
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
          <div class="flex items-center justify-end gap-3">
            <label
              v-if="hasTimeout"
              :for="`call-announcement-${kind}-timeout-${inbox.id}`"
              class="flex items-center gap-2 mb-0 me-auto text-body-main text-n-slate-12"
            >
              <span
                class="flex items-center gap-2 h-8 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 -outline-offset-1 outline-n-weak focus-within:outline-n-brand"
              >
                <input
                  :id="`call-announcement-${kind}-timeout-${inbox.id}`"
                  v-model="timeout"
                  type="number"
                  :min="TIMEOUT_SECONDS.min"
                  :max="TIMEOUT_SECONDS.max"
                  :disabled="isSaving"
                  class="w-10 reset-base !mb-0 !p-0 !border-0 !bg-transparent text-sm text-n-slate-12"
                />
                <span class="text-sm text-n-slate-11">
                  {{ label('TIMEOUT.UNIT') }}
                </span>
              </span>
              {{ label('TIMEOUT.LABEL') }}
              <span class="ps-2 border-s border-n-weak text-n-slate-11">
                {{ label('TIMEOUT.RANGE') }}
              </span>
            </label>
            <NextButton
              :label="$t('INBOX_MGMT.VOICE_CONFIGURATION.ANNOUNCEMENT.SAVE')"
              :is-loading="isSaving"
              :disabled="!canSave"
              sm
              @click="save()"
            />
          </div>
        </div>
      </template>
    </component>
  </div>
</template>
