<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessagePreview from './MessagePreview.vue';
import VoiceCallStatus from './VoiceCallStatus.vue';
import UnreadBadge from './UnreadBadge.vue';

defineProps({
  lastMessage: { type: Object, default: null },
  voiceCallStatus: { type: String, default: '' },
  voiceCallDirection: { type: String, default: '' },
  unreadCount: { type: Number, default: 0 },
  showExpandedPreview: { type: Boolean, default: false },
});
</script>

<template>
  <div
    class="grid grid-cols-[1fr_auto] gap-1.5"
    :class="showExpandedPreview ? 'items-end' : 'items-center'"
  >
    <VoiceCallStatus
      v-if="voiceCallStatus"
      key="voice-status-row"
      :status="voiceCallStatus"
      :direction="voiceCallDirection"
      :class="unreadCount > 0 ? 'text-n-slate-12' : 'text-n-slate-11'"
    />
    <MessagePreview
      v-else-if="lastMessage"
      key="message-preview"
      :message="lastMessage"
      :multi-line="showExpandedPreview"
      :class="unreadCount > 0 ? 'text-n-slate-12' : 'text-n-slate-11'"
    />
    <span
      v-else
      key="no-messages"
      class="inline-grid grid-flow-col auto-cols-max items-center gap-1 text-body-main"
      :class="unreadCount > 0 ? 'text-n-slate-12' : 'text-n-slate-11'"
    >
      <Icon icon="i-lucide-info" class="size-3.5" />
      {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
    </span>

    <UnreadBadge :count="unreadCount" :align-bottom="showExpandedPreview" />
  </div>
</template>
