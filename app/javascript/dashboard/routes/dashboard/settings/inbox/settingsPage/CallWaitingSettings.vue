<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const ACCEPTED_AUDIO_TYPES = 'audio/mpeg,audio/wav,.mp3,.wav';
const store = useStore();
const { t } = useI18n();
const fileInput = ref(null);
const isSaving = ref(false);
const joinBeepEnabled = ref(props.inbox.call_join_beep_enabled !== false);
const audioUrl = computed(() => props.inbox.call_waiting_audio_url);

watch(
  () => props.inbox.call_join_beep_enabled,
  value => {
    joinBeepEnabled.value = value !== false;
  }
);

// Runs one save at a time; a failed one surfaces the server's reason
const save = async action => {
  if (isSaving.value) return false;
  isSaving.value = true;
  try {
    await action();
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    return true;
  } catch (error) {
    useAlert(
      error?.response?.data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
    return false;
  } finally {
    isSaving.value = false;
  }
};

const uploadAudio = event => {
  const [file] = event.target.files || [];
  // Clear the input so choosing the same file again fires change
  event.target.value = '';
  if (!file) return;
  save(() =>
    store.dispatch('inboxes/uploadCallWaitingAudio', {
      id: props.inbox.id,
      file,
    })
  );
};

const removeAudio = () =>
  save(() =>
    store.dispatch('inboxes/removeCallWaitingAudio', { id: props.inbox.id })
  );

const toggleJoinBeep = async value => {
  joinBeepEnabled.value = value;
  const saved = await save(() =>
    store.dispatch('inboxes/updateCallJoinBeep', {
      id: props.inbox.id,
      enabled: value,
    })
  );
  if (!saved)
    joinBeepEnabled.value = props.inbox.call_join_beep_enabled !== false;
};
</script>

<template>
  <div
    class="flex flex-col gap-6"
    :class="{ 'pointer-events-none opacity-60': isSaving }"
  >
    <SettingsToggleSection
      hide-toggle
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.LABEL')"
      :description="
        $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.DESCRIPTION')
      "
    >
      <template #editor>
        <div class="flex flex-col gap-3">
          <template v-if="audioUrl">
            <span class="text-body-main text-n-slate-12">{{
              $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.CURRENT')
            }}</span>
            <audio
              :key="audioUrl"
              :src="audioUrl"
              controls
              class="w-full"
              :aria-label="
                $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.CURRENT')
              "
            />
          </template>
          <p class="text-body-main text-n-slate-11">
            {{ $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.HELP') }}
          </p>
          <input
            ref="fileInput"
            type="file"
            :accept="ACCEPTED_AUDIO_TYPES"
            class="hidden"
            @change="uploadAudio"
          />
          <div class="flex gap-2">
            <NextButton
              :label="
                audioUrl
                  ? $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.REPLACE')
                  : $t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.UPLOAD')
              "
              :is-loading="isSaving"
              @click="fileInput.click()"
            />
            <NextButton
              v-if="audioUrl"
              :label="$t('INBOX_MGMT.VOICE_CONFIGURATION.WAITING_AUDIO.REMOVE')"
              slate
              faded
              :disabled="isSaving"
              @click="removeAudio"
            />
          </div>
        </div>
      </template>
    </SettingsToggleSection>

    <SettingsToggleSection
      :model-value="joinBeepEnabled"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.JOIN_BEEP.LABEL')"
      :description="$t('INBOX_MGMT.VOICE_CONFIGURATION.JOIN_BEEP.DESCRIPTION')"
      @update:model-value="toggleJoinBeep"
    />
  </div>
</template>
