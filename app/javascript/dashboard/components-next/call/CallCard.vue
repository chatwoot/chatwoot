<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

defineEmits([
  'accept',
  'reject',
  'end',
  'toggleMute',
  'goToConversation',
  'dismiss',
]);

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
    class="flex flex-col gap-2 pt-4 bg-n-solid-2/95 rounded-2xl shadow-xl outline outline-1 outline-n-strong backdrop-blur-md"
    :class="call?.conversationId ? 'pb-2' : 'pb-4'"
  >
    <!-- Top section: status badge + location/inbox + duration -->
    <div class="flex flex-col gap-3">
      <div class="flex items-center gap-2 px-4">
        <!-- Ongoing: status badge on left -->
        <div v-if="isOngoing" class="flex items-center gap-1.5 shrink-0">
          <Icon :icon="statusIcon" class="size-3.5 text-n-teal-9 shrink-0" />
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
          <Icon
            v-else-if="!isOngoing"
            :icon="channelIcon"
            class="size-3.5 text-n-slate-10 shrink-0"
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
          <Icon :icon="statusIcon" class="size-3.5 text-n-teal-9 shrink-0" />
          <span class="text-xs font-medium text-n-teal-9 tracking-tight">
            {{ statusLabel }}
          </span>
          <!-- Dismiss: removes the notification from the UI without declining.
               Incoming only — outgoing/ongoing calls are ended via the call
               controls, not silently dismissed. -->
          <NextButton
            v-if="isIncoming"
            v-tooltip.top="$t('CONVERSATION.VOICE_WIDGET.DISMISS_CALL')"
            icon="i-ph-x-bold"
            slate
            ghost
            xs
            class="!rounded-full -my-1"
            @click="$emit('dismiss')"
          />
        </div>
      </div>

      <!-- Main row: avatar + name/phone + actions -->
      <div class="flex items-center gap-3 px-4">
        <div class="shrink-0">
          <Avatar
            :src="callInfo.avatar"
            :name="callInfo.contactName"
            :size="40"
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
          <NextButton
            v-if="isOngoing && showMute"
            v-tooltip.top="
              isMuted
                ? $t('CONVERSATION.VOICE_WIDGET.UNMUTE')
                : $t('CONVERSATION.VOICE_WIDGET.MUTE')
            "
            :icon="
              isMuted ? 'i-ph-microphone-slash-bold' : 'i-ph-microphone-bold'
            "
            :variant="isMuted ? 'solid' : 'faded'"
            :color="isMuted ? 'amber' : 'teal'"
            class="!rounded-full"
            @click="$emit('toggleMute')"
          />

          <!-- Accept call (incoming only) -->
          <NextButton
            v-if="isIncoming"
            v-tooltip.top="$t('CONVERSATION.VOICE_WIDGET.JOIN_CALL')"
            icon="i-ph-phone-bold"
            teal
            class="!rounded-full"
            @click="$emit('accept')"
          />

          <!-- Reject / end call (all states) -->
          <NextButton
            v-tooltip.top="
              isOngoing
                ? $t('CONVERSATION.VOICE_WIDGET.END_CALL')
                : $t('CONVERSATION.VOICE_WIDGET.REJECT_CALL')
            "
            icon="i-ph-phone-x-bold"
            ruby
            class="!rounded-full rotate-[134deg]"
            @click="isOngoing ? $emit('end') : $emit('reject')"
          />
        </div>
      </div>
    </div>

    <!-- Footer: go to conversation thread -->
    <NextButton
      v-if="call?.conversationId"
      slate
      ghost
      trailing-icon
      class="!justify-between !px-2 !mx-2"
      @click="$emit('goToConversation')"
    >
      <template #icon>
        <span
          class="flex items-center gap-1 text-n-slate-11 group-hover:text-n-slate-12"
        >
          <Icon
            icon="i-ph-chat-circle-text-bold"
            class="size-3.5 text-n-slate-11 shrink-0"
          />
          <span class="text-sm tracking-tight tabular-nums">
            #{{ call.conversationId }}
          </span>
          <Icon
            icon="i-ph-caret-right-bold"
            class="size-3 text-n-slate-11 shrink-0"
          />
        </span>
      </template>
      <span
        class="text-sm text-n-slate-11 tracking-tight group-hover:text-n-slate-12"
      >
        {{ $t('CONVERSATION.VOICE_WIDGET.GO_TO_CONVERSATION') }}
      </span>
    </NextButton>
  </div>
</template>
