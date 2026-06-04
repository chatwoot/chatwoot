<script setup>
import { computed, onUnmounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import CustomVoiceClient from 'dashboard/api/channel/voice/customVoiceClient';

const store = useStore();

const RETRY_STEPS_SECONDS = [15, 30, 45, 60];
const PAUSE_SECONDS = 120;

const retryIndex = ref(0);
const timerId = ref(null);
const isRegistering = ref(false);
const lastInboxId = ref(null);

const inboxes = computed(() => store.getters['inboxes/getInboxes'] || []);
const customVoiceInboxes = computed(() =>
  inboxes.value.filter(
    inbox => inbox.channel_type === INBOX_TYPES.VOICE && inbox.provider === 'custom'
  )
);

const clearTimer = () => {
  if (timerId.value) {
    clearTimeout(timerId.value);
    timerId.value = null;
  }
};

const scheduleNextAttempt = seconds => {
  clearTimer();
  timerId.value = setTimeout(() => {
    attemptRegister('retry');
  }, seconds * 1000);
};

const validateTokenResponse = data => {
  if (!data || data.provider !== 'custom') return false;
  if (!data.webrtc?.ws_url || !data.webrtc?.sip_domain) return false;
  if (!data.webrtc?.username) return false;

  const authType = data.auth_type || 'jwt';
  if (authType === 'password') return !!data.password;
  return !!data.token;
};

const resolveInboxWithCredentials = async () => {
  for (const inbox of customVoiceInboxes.value) {
    try {
      const response = await VoiceAPI.getToken(inbox.id);
      if (validateTokenResponse(response)) return inbox;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn('[VoiceAutoRegister] token check failed', {
        inboxId: inbox.id,
        error,
      });
    }
  }
  return null;
};

const recordFailureAndSchedule = () => {
  if (retryIndex.value < RETRY_STEPS_SECONDS.length) {
    const delay = RETRY_STEPS_SECONDS[retryIndex.value];
    retryIndex.value += 1;
    scheduleNextAttempt(delay);
    return;
  }

  retryIndex.value = 0;
  scheduleNextAttempt(PAUSE_SECONDS);
};

const attemptRegister = async reason => {
  if (isRegistering.value) return;
  if (!customVoiceInboxes.value.length) return;

  isRegistering.value = true;
  try {
    const inbox = await resolveInboxWithCredentials();
    if (!inbox?.id) {
      // eslint-disable-next-line no-console
      console.log('[VoiceAutoRegister] no valid credentials, retry later');
      recordFailureAndSchedule();
      return;
    }

    if (lastInboxId.value && lastInboxId.value !== inbox.id) {
      CustomVoiceClient.destroyDevice();
    }
    lastInboxId.value = inbox.id;

    // eslint-disable-next-line no-console
    console.log('[VoiceAutoRegister] register start', { inboxId: inbox.id, reason });
    await CustomVoiceClient.initializeDevice(inbox.id);
    // eslint-disable-next-line no-console
    console.log('[VoiceAutoRegister] register success', { inboxId: inbox.id });
    retryIndex.value = 0;
    clearTimer();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn('[VoiceAutoRegister] register failed', { error });
    recordFailureAndSchedule();
  } finally {
    isRegistering.value = false;
  }
};

watch(
  customVoiceInboxes,
  inboxList => {
    if (!inboxList.length) {
      clearTimer();
      retryIndex.value = 0;
      lastInboxId.value = null;
      return;
    }
    attemptRegister('initial');
  },
  { immediate: true }
);

onUnmounted(() => {
  clearTimer();
});
</script>

<template>
  <span class="hidden" />
</template>
