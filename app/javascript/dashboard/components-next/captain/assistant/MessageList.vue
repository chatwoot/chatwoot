<script setup>
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineProps({
  messages: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();

const isUserMessage = sender => sender === 'user';

const getMessageAlignment = sender =>
  isUserMessage(sender) ? 'justify-end' : 'justify-start';

const getMessageDirection = sender =>
  isUserMessage(sender) ? 'flex-row-reverse' : 'flex-row';

const getAvatarName = sender =>
  isUserMessage(sender)
    ? t('CAPTAIN.PLAYGROUND.USER')
    : t('CAPTAIN.PLAYGROUND.ASSISTANT');

const getMessageStyle = sender =>
  isUserMessage(sender)
    ? 'bg-n-strong text-n-white'
    : 'bg-n-solid-iris text-n-slate-12';
</script>

<template>
  <div class="flex-1 overflow-y-auto mb-4 space-y-2">
    <div
      v-for="(message, index) in messages"
      :key="index"
      class="flex"
      :class="getMessageAlignment(message.sender)"
    >
      <div
        class="flex items-start gap-1.5"
        :class="getMessageDirection(message.sender)"
      >
        <Avatar :name="getAvatarName(message.sender)" rounded-full :size="24" />
        <div
          class="max-w-sm rounded-lg p-3 text-sm"
          :class="getMessageStyle(message.sender)"
        >
          {{ message.content }}
        </div>
      </div>
    </div>
  </div>
</template>
