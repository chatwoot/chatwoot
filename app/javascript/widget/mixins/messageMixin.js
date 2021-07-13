export default {
  computed: {
    messageContentAttributes() {
      const { content_attributes: attribute = {} } = this.message;
      return attribute;
    },
    isMessageDeleted() {
      return this.messageContentAttributes.deleted;
    },
    hasAttachments() {
      return !!(
        this.message.attachments && this.message.attachments.length > 0
      );
    },
  },
};
