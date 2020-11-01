<template>
  <button
    class="px-5 py-4 text-black-700
        flex flex-row items-center justify-between
        border-b border-solid border-slate-50 last:border-b-0
        w-full hover:bg-woot-50
        "
    @click="onClick"
  >
    <div class="text-left">
      <div class="mb-2 text-xs font-medium">
        {{ dynamicTime(conversation.timestamp) }}
      </div>
      <div class="text-sm">
        <span>{{ `${senderName}: ` }}</span>
        <span v-if="lastMessageInChat.content">
          {{ lastMessageInChat.content }}
        </span>
        <span v-else-if="!lastMessageInChat.attachments">{{ ` ` }}</span>
        <span v-else>
          <i :class="`small-icon ${this.$t(`${attachmentIconKey}.ICON`)}`"></i>
          {{ this.$t(`${attachmentIconKey}.CONTENT`) }}
        </span>
      </div>
    </div>
    <div>
      <i class="ion-chevron-right" />
    </div>
  </button>
</template>

<script>
import timeMixin from 'shared/mixins/time';

export default {
  mixins: [timeMixin],
  props: {
    conversation: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    senderName() {
      const { sender } = this.lastMessageInChat;
      return sender ? sender.available_name : 'Bot';
    },
    lastMessageInChat() {
      return this.conversation.messages[this.conversation.messages.length - 1];
    },
    attachmentIconKey() {
      const [{ file_type: fileType } = {}] = this.lastMessageInChat.attachments;
      return `ATTACHMENTS.${fileType}`;
    },
  },
  methods: {
    onClick() {
      this.$emit('click', this.conversation.id);
    },
  },
};
</script>
