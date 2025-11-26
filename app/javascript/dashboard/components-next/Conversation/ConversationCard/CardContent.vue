<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessagePreview from './MessagePreview.vue';
import VoiceCallStatus from './VoiceCallStatus.vue';

const props = defineProps({
  lastMessage: { type: Object, default: null },
  voiceCallStatus: { type: String, default: '' },
  voiceCallDirection: { type: String, default: '' },
  unreadCount: { type: Number, default: 0 },
  showExpandedPreview: { type: Boolean, default: false },
});

const hasUnread = computed(() => props.unreadCount > 0);

const displayCount = computed(() =>
  props.unreadCount > 9 ? '9+' : props.unreadCount
);
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
      :class="hasUnread ? 'text-n-slate-12' : 'text-n-slate-11'"
    />
    <MessagePreview
      v-else-if="lastMessage"
      key="message-preview"
      :message="lastMessage"
      :multi-line="showExpandedPreview"
      :class="hasUnread ? 'text-n-slate-12' : 'text-n-slate-11'"
    />
    <span
      v-else
      key="no-messages"
      class="inline-grid grid-flow-col auto-cols-max items-center gap-1 text-sm font-420"
      :class="hasUnread ? 'text-n-slate-12' : 'text-n-slate-11'"
    >
      <Icon icon="i-lucide-info" class="size-3.5" />
      {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
    </span>

    <span
      v-if="hasUnread"
      class="bg-n-blue-9 rounded-full h-4 min-w-4 max-w-5 px-1 w-fit font-medium text-xxs leading-3 text-white place-items-center"
      :class="{
        'mb-0.5': showExpandedPreview,
        'inline-grid': hasUnread,
        hidden: !hasUnread,
      }"
    >
      {{ displayCount }}
    </span>
  </div>
</template>
