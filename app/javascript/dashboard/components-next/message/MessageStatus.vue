<script setup>
import { computed, ref } from 'vue';
import { useIntervalFn } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { MESSAGE_STATUS, MESSAGE_VARIANTS } from './constants';
import { useMessageContext } from './provider.js';

import Icon from 'next/icon/Icon.vue';

const { status } = defineProps({
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
});

const { t } = useI18n();
const { variant } = useMessageContext();

const variantPrefix = computed(() => {
  const prefixMap = {
    [MESSAGE_VARIANTS.AGENT]: 'agent',
    [MESSAGE_VARIANTS.USER]: 'user',
    [MESSAGE_VARIANTS.PRIVATE]: 'private',
    [MESSAGE_VARIANTS.BOT]: 'bot',
    [MESSAGE_VARIANTS.TEMPLATE]: 'bot',
    [MESSAGE_VARIANTS.EMAIL]: 'agent',
  };
  return prefixMap[variant.value] || 'agent';
});

const progresIconSequence = [
  'i-lucide-clock-1',
  'i-lucide-clock-2',
  'i-lucide-clock-3',
  'i-lucide-clock-4',
  'i-lucide-clock-5',
  'i-lucide-clock-6',
  'i-lucide-clock-7',
  'i-lucide-clock-8',
  'i-lucide-clock-9',
  'i-lucide-clock-10',
  'i-lucide-clock-11',
  'i-lucide-clock-12',
];

const progessIcon = ref(progresIconSequence[0]);

const rotateIcon = () => {
  const currentIndex = progresIconSequence.indexOf(progessIcon.value);
  const nextIndex = (currentIndex + 1) % progresIconSequence.length;
  progessIcon.value = progresIconSequence[nextIndex];
};

useIntervalFn(rotateIcon, 500, {
  immediate: status === MESSAGE_STATUS.PROGRESS,
  immediateCallback: false,
});

const statusIcon = computed(() => {
  const statusIconMap = {
    [MESSAGE_STATUS.SENT]: 'i-lucide-check',
    [MESSAGE_STATUS.DELIVERED]: 'i-lucide-check-check',
    [MESSAGE_STATUS.READ]: 'i-lucide-check-check',
  };

  return statusIconMap[status];
});

const statusColorMap = {
  agent: {
    [MESSAGE_STATUS.SENT]: 'text-[rgb(var(--bubble-agent-status))]',
    [MESSAGE_STATUS.DELIVERED]: 'text-[rgb(var(--bubble-agent-status))]',
    [MESSAGE_STATUS.READ]: 'text-[rgb(var(--bubble-agent-status-read))]',
  },
  user: {
    [MESSAGE_STATUS.SENT]: 'text-[rgb(var(--bubble-user-status))]',
    [MESSAGE_STATUS.DELIVERED]: 'text-[rgb(var(--bubble-user-status))]',
    [MESSAGE_STATUS.READ]: 'text-[rgb(var(--bubble-user-status-read))]',
  },
  private: {
    [MESSAGE_STATUS.SENT]: 'text-[rgb(var(--bubble-private-status))]',
    [MESSAGE_STATUS.DELIVERED]: 'text-[rgb(var(--bubble-private-status))]',
    [MESSAGE_STATUS.READ]: 'text-[rgb(var(--bubble-private-status-read))]',
  },
  bot: {
    [MESSAGE_STATUS.SENT]: 'text-[rgb(var(--bubble-bot-status))]',
    [MESSAGE_STATUS.DELIVERED]: 'text-[rgb(var(--bubble-bot-status))]',
    [MESSAGE_STATUS.READ]: 'text-[rgb(var(--bubble-bot-status-read))]',
  },
};

const statusColor = computed(() => {
  const variantMap =
    statusColorMap[variantPrefix.value] || statusColorMap.agent;
  return variantMap[status];
});

const progressColorMap = {
  agent: 'text-[rgb(var(--bubble-agent-status))]',
  user: 'text-[rgb(var(--bubble-user-status))]',
  private: 'text-[rgb(var(--bubble-private-status))]',
  bot: 'text-[rgb(var(--bubble-bot-status))]',
};

const progressColor = computed(() => {
  return progressColorMap[variantPrefix.value] || progressColorMap.agent;
});

const tooltipText = computed(() => {
  const statusTextMap = {
    [MESSAGE_STATUS.SENT]: t('CHAT_LIST.SENT'),
    [MESSAGE_STATUS.DELIVERED]: t('CHAT_LIST.DELIVERED'),
    [MESSAGE_STATUS.READ]: t('CHAT_LIST.MESSAGE_READ'),
    [MESSAGE_STATUS.PROGRESS]: t('CHAT_LIST.SENDING'),
  };

  return statusTextMap[status];
});
</script>

<template>
  <Icon
    v-if="status === MESSAGE_STATUS.PROGRESS"
    v-tooltip.top-start="tooltipText"
    :icon="progessIcon"
    :class="progressColor"
  />
  <Icon
    v-else
    v-tooltip.top-start="tooltipText"
    :icon="statusIcon"
    :class="statusColor"
    class="size-[14px]"
  />
</template>
