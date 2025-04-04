<script setup>
import { computed, ref } from 'vue';
import DyteAPI from 'dashboard/api/integrations/dyte';
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import { useMessageContext } from '../provider.js';
import BaseAttachmentBubble from './BaseAttachment.vue';

const { content, sender, id } = useMessageContext();

const { t } = useI18n();

const isLoading = ref(false);
const dyteAuthToken = ref('');

const meetingLink = computed(() => {
  return buildDyteURL(dyteAuthToken.value);
});

const joinTheCall = async () => {
  isLoading.value = true;
  try {
    const { data: { token } = {} } = await DyteAPI.addParticipantToMeeting(
      id.value
    );
    dyteAuthToken.value = token;
  } catch (err) {
    useAlert(t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const leaveTheRoom = () => {
  dyteAuthToken.value = '';
};
const action = computed(() => ({
  label: t('INTEGRATION_SETTINGS.DYTE.CLICK_HERE_TO_JOIN'),
  onClick: joinTheCall,
}));
</script>

<template>
  <BaseAttachmentBubble
    icon="i-ph-video-camera-fill"
    icon-bg-color="bg-[#2781F6]"
    sender-translation-key="CONVERSATION.SHARED_ATTACHMENT.MEETING"
    :action="action"
  >
    <div v-if="!sender" class="text-sm truncate text-n-slate-12">
      <!-- Added as a fallback, where the sender is not available (Deleted) -->
      <!-- Will show the content, if senderName in BaseAttachment.vue is empty -->
      {{ content }}
    </div>
    <div v-if="dyteAuthToken" class="video-call--container">
      <iframe
        :src="meetingLink"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;"
      />
      <button
        class="px-4 py-2 text-sm rounded-lg bg-n-solid-3 mt-3"
        @click="leaveTheRoom"
      >
        {{ $t('INTEGRATION_SETTINGS.DYTE.LEAVE_THE_ROOM') }}
      </button>
    </div>
    <div v-else>
      {{ '' }}
    </div>
  </BaseAttachmentBubble>
</template>

<style lang="scss">
.join-call-button {
  margin: var(--space-small) 0;
}

.video-call--container {
  position: fixed;
  bottom: 0;
  right: 0;
  width: 100%;
  height: 100%;
  z-index: var(--z-index-high);
  padding: var(--space-smaller);
  background: var(--b-800);

  iframe {
    width: 100%;
    height: 100%;
    border: 0;
  }

  button {
    position: absolute;
    top: var(--space-smaller);
    right: 10rem;
  }
}
</style>
