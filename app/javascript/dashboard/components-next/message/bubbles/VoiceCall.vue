<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';
import { formatDuration } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

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

const { t } = useI18n();
const { contentAttributes, currentUserId, messageType } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);
const status = computed(() => data.value?.status?.toString());
const joinedBy = computed(() => {
  return data.value?.meta?.joinedBy || data.value?.meta?.joined_by;
});
const callDuration = computed(() => {
  return data.value?.meta?.duration;
});

const isOutbound = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);
const didCurrentUserAnswer = computed(() => {
  return joinedBy.value?.id === currentUserId.value;
});

const label = computed(() => {
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
  }

  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
  }

  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? t('CONVERSATION.VOICE_CALL.OUTGOING_CALL')
      : t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
  }

  return isFailed.value
    ? t('CONVERSATION.VOICE_CALL.MISSED_CALL')
    : t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
});

const subtext = computed(() => {
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
  }

  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return (
      formatDuration(callDuration.value) ||
      t('CONVERSATION.VOICE_CALL.CALL_ENDED')
    );
  }

  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    if (didCurrentUserAnswer.value) {
      return t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
    }

    if (joinedBy.value?.name) {
      return t('CONVERSATION.VOICE_CALL.AGENT_ANSWERED', {
        agentName: joinedBy.value.name,
      });
    }

    return t('CONVERSATION.VOICE_CALL.THEY_ANSWERED');
  }

  return isFailed.value
    ? t('CONVERSATION.VOICE_CALL.NO_ANSWER')
    : t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
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
            {{ label }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{ subtext }}
          </span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
