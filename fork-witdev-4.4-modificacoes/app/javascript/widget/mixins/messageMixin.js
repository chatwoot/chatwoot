export default {
  computed: {
    messageContentAttributes() {
      const { content_attributes: attribute = {} } = this.message;
      return attribute;
    },
    hasAttachments() {
      return !!(
        this.message.attachments && this.message.attachments.length > 0
      );
    },
  },
};
