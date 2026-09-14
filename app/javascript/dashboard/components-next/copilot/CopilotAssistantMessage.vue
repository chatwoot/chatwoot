<script setup>
import { computed } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isLastMessage: {
    type: Boolean,
    default: false,
  },
  message: {
    type: Object,
    required: true,
  },
});
const hasEmptyMessageContent = computed(() => !props.message?.content);

const showUseButton = computed(() => {
  return (
    !hasEmptyMessageContent.value &&
    props.message.reply_suggestion &&
    props.isLastMessage
  );
});

const messageContent = computed(() => {
  const formatter = new MessageFormatter(props.message.content);
  return formatter.formattedMessage;
});

const useCopilotResponse = () => {
  // Always insert through the rich editor so the markdown is parsed into proper
  // paragraph/hard_break nodes. The plain-text path inserts the reply as a single
  // text node with raw newlines, which the editor collapses into one paragraph as
  // soon as the agent edits the draft.
  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
  useTrack(COPILOT_EVENTS.USE_CAPTAIN_RESPONSE);
};
</script>

<template>
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
        v-if="showUseButton"
        :label="$t('CAPTAIN.COPILOT.USE')"
        faded
        sm
        slate
        @click="useCopilotResponse"
      />
    </div>
  </div>
</template>
