<script setup>
import { computed, ref } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from '../provider.js';
import { useVoiceCallStatus } from 'dashboard/composables/useVoiceCallStatus';
import VoiceAPI from 'dashboard/api/channels/voice';
import { useStore } from 'vuex';
import { MESSAGE_TYPES } from 'dashboard/components-next/message/constants.js';

const store = useStore();
const { contentAttributes, conversationId, inboxId, messageType } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);

const status = computed(() => data.value?.status);
const direction = computed(() => {
  const dir = data.value?.call_direction;
  if (dir) return dir;
  const mt = messageType?.value;
  if (mt === MESSAGE_TYPES.OUTGOING) return 'outbound';
  if (mt === MESSAGE_TYPES.INCOMING) return 'inbound';
  return undefined;
});

const { labelKey, subtextKey, bubbleIconBg, bubbleIconName } =
  useVoiceCallStatus(status, direction);

const containerRingClass = computed(() => {
  return status.value === 'ringing' ? 'ring-1 ring-emerald-300' : '';
});

// Make join available whenever the call is ringing
const isJoinable = computed(() => status.value === 'ringing');
const isJoining = ref(false);

const joinConference = async () => {
  if (!isJoinable.value || isJoining.value) return;
  try {
    isJoining.value = true;
    await VoiceAPI.initializeDevice(inboxId.value, { store });
    const res = await VoiceAPI.joinConference({
      inbox_id: inboxId.value,
      conversation_id: conversationId.value,
      call_sid: contentAttributes.value?.data?.call_sid,
    });
    const conferenceSid = res?.conference_sid;
    if (conferenceSid) {
      VoiceAPI.joinClientCall({ To: conferenceSid, conversationId: conversationId.value });

      const currentIncoming = store.getters['calls/getIncomingCall'];
      const callSidToUse = currentIncoming?.callSid || contentAttributes.value?.data?.call_sid;

      if (callSidToUse) {
        store.dispatch('calls/setActiveCall', {
          callSid: callSidToUse,
          conversationId: conversationId.value,
          inboxId: inboxId.value,
          isJoined: true,
          startedAt: Date.now(),
        });
        // Clear any incoming banner and stop ringtone if present
        try { store.dispatch('calls/clearIncomingCall'); } catch (_) {}
        try { if (typeof window.stopAudioAlert === 'function') window.stopAudioAlert(); } catch (_) {}
      }
    }
  } catch (_) {
    // ignore join errors here; UI will remain joinable
  } finally {
    isJoining.value = false;
  }
};
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div
      class="flex overflow-hidden flex-col w-full max-w-xs bg-white rounded-lg border border-slate-100 text-slate-900 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
      :class="[containerRingClass, { 'cursor-pointer': isJoinable }]"
      :tabindex="isJoinable ? 0 : -1"
      :role="isJoinable ? 'button' : 'article'"
      :aria-label="isJoinable ? $t('CONVERSATION.VOICE_CALL.JOIN_CALL') : ''"
      :title="isJoinable ? $t('CONVERSATION.VOICE_CALL.JOIN_CALL') : ''"
      @click.prevent.stop="joinConference"
      @keydown.enter.prevent.stop="joinConference"
      @keydown.space.prevent.stop="joinConference"
    >
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bubbleIconBg"
        >
          <span class="text-xl" :class="bubbleIconName" />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-base font-medium truncate">{{ $t(labelKey) }}</span>
          <span class="text-xs text-slate-500">{{ $t(subtextKey) }}</span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
