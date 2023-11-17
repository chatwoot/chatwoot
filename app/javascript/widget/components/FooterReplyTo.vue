<template>
  <div
    class="mb-2.5 rounded-[7px] dark:bg-slate-900 dark:text-slate-100 bg-slate-100 px-2 py-1.5 text-sm text-slate-700 flex items-center gap-2"
  >
    <div class="items-center flex-grow truncate">
      <strong>Replying to:</strong>
      {{ inReplyTo.content || replyToAttachment }}
    </div>
    <button
      class="items-end flex-shrink-0 p-1 rounded-md hover:bg-slate-200 dark:hover:bg-slate-800"
      @click="$emit('dismiss')"
    >
      <fluent-icon icon="dismiss" size="12" />
    </button>
  </div>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'FooterReplyTo',
  components: { FluentIcon },
  props: {
    inReplyTo: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    replyToAttachment() {
      if (!this.inReplyTo?.attachments?.length) {
        return '';
      }

      const [{ file_type: fileType } = {}] = this.inReplyTo.attachments;
      return this.$t(`ATTACHMENTS.${fileType}.CONTENT`);
    },
  },
};
</script>
