<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';

const props = defineProps({
  call: {
    type: Object,
    required: true,
  },
  callInfo: {
    type: Object,
    required: true,
  },
  // 'incoming' | 'outgoing' | 'ongoing'
  state: {
    type: String,
    required: true,
  },
  duration: {
    type: String,
    default: '',
  },
  isMuted: {
    type: Boolean,
    default: false,
  },
  showMute: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['accept', 'reject', 'end', 'toggleMute', 'goToConversation']);

const { t } = useI18n();

const isOngoing = computed(() => props.state === VOICE_CALL_DIRECTION.ONGOING);
const isIncoming = computed(
  () => props.state === VOICE_CALL_DIRECTION.INCOMING
);
const isOutgoing = computed(
  () => props.state === VOICE_CALL_DIRECTION.OUTGOING
);

const statusIcon = computed(() => {
  if (isOngoing.value) return 'i-ph-phone-call-bold';
  if (isOutgoing.value) return 'i-ph-phone-outgoing-bold';
  return 'i-ph-phone-incoming-bold';
});

const statusLabel = computed(() => {
  if (isOngoing.value) return t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS');
  if (isOutgoing.value) return t('CONVERSATION.VOICE_WIDGET.OUTGOING_CALL');
  return t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL');
});

const channelIcon = computed(() => {
  if (props.call?.provider === VOICE_CALL_PROVIDERS.WHATSAPP)
    return 'i-ri-whatsapp-fill';
  return 'i-ph-phone-bold';
});
</script>

<template>
  <div
    class="flex flex-col gap-3 pt-4 pb-4 bg-n-solid-2/95 rounded-2xl shadow-xl outline outline-1 outline-n-strong backdrop-blur-md"
  >
    <!-- Top section: status badge + location/inbox + duration -->
    <div class="flex flex-col gap-3 pb-2">
      <div class="flex items-center gap-2 px-4">
        <!-- Ongoing: status badge on left -->
        <div v-if="isOngoing" class="flex items-center gap-1.5 shrink-0">
          <i class="text-sm text-n-teal-9" :class="statusIcon" />
          <span class="text-xs font-medium text-n-teal-9 tracking-tight">
            {{ statusLabel }}
          </span>
        </div>

        <!-- Caller location (city, country) or fallback to channel + inbox name -->
        <div class="flex items-center gap-1.5 min-w-0 flex-1">
          <span
            v-if="callInfo.hasLocation && callInfo.countryFlag"
            class="text-sm leading-none shrink-0"
          >
            {{ callInfo.countryFlag }}
          </span>
          <i
            v-else-if="!isOngoing"
            class="text-sm text-n-slate-10 shrink-0"
            :class="channelIcon"
          />
          <span
            class="text-xs font-medium text-n-slate-11 tracking-tight truncate"
          >
            {{ callInfo.location }}
          </span>
        </div>

        <!-- Ongoing: duration on right -->
        <p
          v-if="isOngoing"
          class="font-display text-base font-medium text-n-slate-11 shrink-0 mb-0 tabular-nums tracking-tight"
        >
          {{ duration }}
        </p>
        <!-- Incoming/Outgoing: status badge on right -->
        <div v-else class="flex items-center gap-1.5 shrink-0">
          <i class="text-sm text-n-teal-9" :class="statusIcon" />
          <span class="text-xs font-medium text-n-teal-9 tracking-tight">
            {{ statusLabel }}
          </span>
        </div>
      </div>

      <!-- Main row: avatar + name/phone + actions -->
      <div class="flex items-end gap-3 px-4">
        <div class="shrink-0">
          <Avatar
            :src="callInfo.avatar"
            :name="callInfo.contactName"
            :size="44"
          />
        </div>
        <div class="flex-1 min-w-0">
          <p
            class="font-display text-sm font-medium text-n-slate-12 truncate mb-0.5 tracking-tight leading-tight"
          >
            {{ callInfo.contactName }}
          </p>
          <p
            v-if="callInfo.phoneNumber"
            class="text-sm text-n-slate-11 truncate mb-0 tracking-tight leading-tight"
          >
            {{ callInfo.phoneNumber }}
          </p>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 shrink-0">
          <!-- Mute toggle (WhatsApp ongoing only) -->
          <button
            v-if="isOngoing && showMute"
            v-tooltip.top="
              isMuted
                ? $t('CONVERSATION.VOICE_WIDGET.UNMUTE')
                : $t('CONVERSATION.VOICE_WIDGET.MUTE')
            "
            class="flex justify-center items-center w-10 h-10 rounded-full transition-colors"
            :class="
              isMuted
                ? 'bg-n-amber-9 hover:bg-n-amber-10 text-white'
                : 'bg-n-teal-3 hover:bg-n-teal-4 text-n-teal-11'
            "
            @click="$emit('toggleMute')"
          >
            <i
              class="text-base"
              :class="
                isMuted ? 'i-ph-microphone-slash-bold' : 'i-ph-microphone-bold'
              "
            />
          </button>

          <!-- Accept call (incoming only) -->
          <button
            v-if="isIncoming"
            v-tooltip.top="$t('CONVERSATION.VOICE_WIDGET.JOIN_CALL')"
            class="flex justify-center items-center w-10 h-10 bg-n-teal-9 hover:bg-n-teal-10 rounded-full transition-colors shadow-sm"
            @click="$emit('accept')"
          >
            <i class="text-base text-white i-ph-phone-bold" />
          </button>

          <!-- Reject / end call (all states) -->
          <button
            v-tooltip.top="
              isOngoing
                ? $t('CONVERSATION.VOICE_WIDGET.END_CALL')
                : $t('CONVERSATION.VOICE_WIDGET.REJECT_CALL')
            "
            class="flex justify-center items-center w-10 h-10 bg-n-ruby-9 hover:bg-n-ruby-10 rounded-full transition-colors shadow-sm"
            @click="isOngoing ? $emit('end') : $emit('reject')"
          >
            <i class="text-base text-white i-ph-phone-x-bold rotate-[134deg]" />
          </button>
        </div>
      </div>
    </div>

    <!-- Footer: go to conversation thread -->
    <button
      v-if="call?.conversationId"
      class="flex items-center justify-between gap-2 px-4 pt-3 border-t border-n-strong hover:bg-n-alpha-1 transition-colors group"
      @click="$emit('goToConversation')"
    >
      <span
        class="text-sm text-n-slate-11 tracking-tight group-hover:text-n-slate-12"
      >
        {{ $t('CONVERSATION.VOICE_WIDGET.GO_TO_CONVERSATION') }}
      </span>
      <span
        class="flex items-center gap-1 text-n-slate-11 group-hover:text-n-slate-12"
      >
        <i class="text-sm i-ph-chat-circle-text-bold" />
        <span class="text-sm tracking-tight tabular-nums">
          #{{ call.conversationId }}
        </span>
        <i class="text-xs i-ph-caret-right-bold" />
      </span>
    </button>
  </div>
</template>
