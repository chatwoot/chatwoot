<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import CustomVoiceClient from 'dashboard/api/channel/voice/customVoiceClient';

const AUDIO_PERMISSION_KEY = 'cw_voice_audio_playback_allowed';

const store = useStore();
const { t } = useI18n();

const showModal = ref(false);
const isRequesting = ref(false);
const errorMessage = ref('');

const inboxes = computed(() => store.getters['inboxes/getInboxes'] || []);
const hasCustomVoiceInbox = computed(() =>
  inboxes.value.some(
    inbox => inbox.channel_type === INBOX_TYPES.VOICE && inbox.provider === 'custom'
  )
);

const getStoredPermission = () => {
  try {
    return localStorage.getItem(AUDIO_PERMISSION_KEY) === 'true';
  } catch {
    return false;
  }
};

const handleAudioBlocked = () => {
  if (!hasCustomVoiceInbox.value) return;
  if (getStoredPermission()) return;
  showModal.value = true;
};

const handleAllow = async () => {
  if (isRequesting.value) return;
  isRequesting.value = true;
  errorMessage.value = '';

  const allowed = await CustomVoiceClient.requestRemoteAudioPlayback('user');
  if (allowed) {
    showModal.value = false;
  } else {
    errorMessage.value = t('WEBPHONE.AUDIO_PLAYBACK.ERROR');
  }
  isRequesting.value = false;
};

const closeModal = () => {
  showModal.value = false;
};

onMounted(() => {
  CustomVoiceClient.addEventListener('call:audio_blocked', handleAudioBlocked);
});

onUnmounted(() => {
  CustomVoiceClient.removeEventListener('call:audio_blocked', handleAudioBlocked);
});
</script>

<template>
  <woot-modal v-model:show="showModal" :on-close="closeModal">
    <div class="flex flex-col gap-4 p-6 w-full max-w-md">
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t('WEBPHONE.AUDIO_PLAYBACK.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11">
        {{ t('WEBPHONE.AUDIO_PLAYBACK.DESCRIPTION') }}
      </p>
      <p v-if="errorMessage" class="text-sm text-n-ruby-9">
        {{ errorMessage }}
      </p>
      <div class="flex justify-end gap-2">
        <NextButton
          faded
          slate
          :label="t('WEBPHONE.AUDIO_PLAYBACK.NOT_NOW')"
          @click="closeModal"
        />
        <NextButton
          :label="t('WEBPHONE.AUDIO_PLAYBACK.ALLOW')"
          :is-loading="isRequesting"
          @click="handleAllow"
        />
      </div>
    </div>
  </woot-modal>
</template>
