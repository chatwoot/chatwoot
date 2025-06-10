<script setup>
import { computed } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from '../avatar/Avatar.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
});

const messageContent = computed(() => {
  const formatter = new MessageFormatter(props.message.content);
  return formatter.formattedMessage;
});

const insertIntoRichEditor = computed(() => {
  return [INBOX_TYPES.WEB, INBOX_TYPES.EMAIL].includes(
    props.conversationInboxType
  );
});

const hasEmptyMessageContent = computed(() => !props.message?.content);

const useCopilotResponse = () => {
  if (insertIntoRichEditor.value) {
    emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
  } else {
    emitter.emit(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, props.message?.content);
  }
  useTrack(COPILOT_EVENTS.USE_CAPTAIN_RESPONSE);
};
</script>

<template>
  <div class="flex flex-row gap-2">
    <Avatar
      name="Captain Copilot"
      icon-name="i-woot-captain"
      :size="24"
      rounded-full
    />
    <div class="flex flex-col gap-1 text-n-slate-12">
      <div class="font-medium">{{ $t('CAPTAIN.NAME') }}</div>
      <span v-if="hasEmptyMessageContent" class="text-n-ruby-11">
        {{ $t('CAPTAIN.COPILOT.EMPTY_MESSAGE') }}
      </span>
      <div
        v-else
        v-dompurify-html="messageContent"
        class="prose-sm break-words"
      />
      <div class="flex flex-row mt-1">
        <Button
          v-if="!hasEmptyMessageContent"
          :label="$t('CAPTAIN.COPILOT.USE')"
          faded
          sm
          slate
          @click="useCopilotResponse"
        />
      </div>
    </div>
  </div>
</template>
