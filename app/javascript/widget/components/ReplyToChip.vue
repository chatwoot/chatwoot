<template>
  <button
    class="px-1.5 py-0.5 rounded-md text-slate-500 bg-slate-50 dark:bg-slate-900 opacity-60 hover:opacity-100 cursor-pointer flex items-center gap-1.5"
    @click="navigateTo(replyTo.id)"
  >
    <fluent-icon icon="arrow-reply" size="12" class="flex-shrink-0" />
    <div
      v-if="replyTo.content"
      v-dompurify-html="formatMessage(replyTo.content, false)"
      class="reply-to-truncate"
    />
    <div v-else-if="replyTo.attachments" class="reply-to-truncate">
      <p>{{ replyToAttachment }}</p>
    </div>
  </button>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'AgentMessage',
  components: {
    FluentIcon,
  },
  mixins: [messageFormatterMixin],
  props: {
    replyTo: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    replyToAttachment() {
      if (!this.replyTo?.attachments.length) {
        return '';
      }

      const [{ file_type: fileType } = {}] = this.replyTo.attachments;
      return this.$t(`ATTACHMENTS.${fileType}.CONTENT`);
    },
  },
  methods: {
    navigateTo(id) {
      const elementId = `cwmsg-${id}`;
      this.$nextTick(() => {
        const el = document.getElementById(elementId);
        el.scrollIntoView();
        el.classList.add('bg-slate-100', 'dark:bg-slate-900');
        setTimeout(() => {
          el.classList.remove('bg-slate-100', 'dark:bg-slate-900');
        }, 500);
      });
    },
  },
};
</script>

<style lang="scss">
.reply-to-truncate > p {
  @apply overflow-hidden truncate max-w-[8rem];
}
</style>
