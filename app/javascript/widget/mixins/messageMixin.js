import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({ conversation: 'conversation/getConversation' }),
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
  methods: {
    totalMessagesSentByContact() {
      let msgs = 0;
      Object.values(this.conversation).forEach(value => {
        if (
          typeof value.sender !== 'undefined' &&
          value.sender.type === 'contact'
        ) {
          msgs += 1;
        }
      });
      return msgs;
    },
  },
};
