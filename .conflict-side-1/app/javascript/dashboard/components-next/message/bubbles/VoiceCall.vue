<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const SUBTEXT_MAP = {
  [VOICE_CALL_STATUS.RINGING]: 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x',
};

const BG_COLOR_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'bg-n-teal-9',
  [VOICE_CALL_STATUS.RINGING]: 'bg-n-teal-9 animate-pulse',
  [VOICE_CALL_STATUS.COMPLETED]: 'bg-n-slate-11',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'bg-n-ruby-9',
  [VOICE_CALL_STATUS.FAILED]: 'bg-n-ruby-9',
};

const { contentAttributes, messageType } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);
const status = computed(() => data.value?.status?.toString());

const isOutbound = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);

const labelKey = computed(() => {
  if (LABEL_MAP[status.value]) return LABEL_MAP[status.value];
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
      : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  }
  return isFailed.value
    ? 'CONVERSATION.VOICE_CALL.MISSED_CALL'
    : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const subtextKey = computed(() => {
  if (SUBTEXT_MAP[status.value]) return SUBTEXT_MAP[status.value];
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.THEY_ANSWERED'
      : 'CONVERSATION.VOICE_CALL.YOU_ANSWERED';
  }
  return isFailed.value
    ? 'CONVERSATION.VOICE_CALL.NO_ANSWER'
    : 'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET';
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
});

const bgColor = computed(() => BG_COLOR_MAP[status.value] || 'bg-n-teal-9');
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div class="flex overflow-hidden flex-col w-full max-w-xs">
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bgColor"
        >
          <Icon
            class="size-5"
            :icon="iconName"
            :class="{
              'text-n-slate-1': status === VOICE_CALL_STATUS.COMPLETED,
              'text-white': status !== VOICE_CALL_STATUS.COMPLETED,
            }"
          />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ $t(labelKey) }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{ $t(subtextKey) }}
          </span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
