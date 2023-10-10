<script setup>
import { computed } from 'vue';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

const { messageContent } = defineProps({
  messageId: {
    type: Number,
    required: true,
  },
  messageContent: {
    type: String,
    default: '',
  },
});

const cleanedContent = computed(() => extractTextFromMarkdown(messageContent));
</script>

<template>
  <div
    class="reply-editor bg-slate-50 rounded-md py-1 pl-2 pr-1 text-xs tracking-wide mt-2 flex items-center gap-1.5 -mx-2 cursor-pointer"
    @click="$emit('navigate-to-message', messageId)"
  >
    <fluent-icon class="flex-shrink-0 icon" icon="arrow-reply" icon-size="14" />
    <div class="flex-grow overflow-hidden text-ellipsis">
      {{ $t('CONVERSATION.REPLYBOX.REPLYING_TO') }} {{ cleanedContent }}.
    </div>
    <woot-button
      v-tooltip="$t('CONVERSATION.REPLYBOX.DISMISS_REPLY')"
      color-scheme="secondary"
      icon="dismiss"
      variant="clear"
      size="tiny"
      class="flex-shrink-0"
      @click.stop="$emit('dismiss')"
    />
  </div>
</template>

<style lang="scss">
// TODO: Remove this
// override for dashboard/assets/scss/widgets/_reply-box.scss
.reply-editor {
  .icon {
    margin-right: 0px !important;
  }
}
</style>
