<template>
  <div
    class="reply-editor bg-slate-50 dark:bg-slate-800 rounded-md py-1 pl-2 pr-1 text-xs tracking-wide mt-2 flex items-center gap-1.5 -mx-2"
  >
    <fluent-icon class="flex-shrink-0 icon" icon="arrow-reply" size="14" />
    <div class="flex-grow gap-1 mt-px text-xs truncate">
      {{ $t('CONVERSATION.REPLYBOX.REPLYING_TO') }}
      <message-preview
        :message="message"
        :show-message-type="false"
        :default-empty-message="$t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND')"
        class="inline"
      />
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

<script>
import MessagePreview from 'dashboard/components/widgets/conversation/MessagePreview.vue';

export default {
  components: { MessagePreview },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
};
</script>

<style lang="scss">
// TODO: Remove this
// override for dashboard/assets/scss/widgets/_reply-box.scss
.reply-editor {
  .icon {
    margin-right: 0px !important;
  }
}
</style>
