import { trimContent } from '@chatwoot/utils';

export default {
  methods: {
    getFromDraft() {
      if (this.conversationIdByRoute) {
        const key = `draft-${this.conversationIdByRoute}-${this.replyType}`;
        const messageFromStore =
          this.$store.getters['draftMessages/get'](key) || '';

        // ensure that the message has signature set based on the ui setting
        this.message = this.toggleSignatureForDraft(messageFromStore);
      }
    },
    removeFromDraft() {
      if (this.conversationIdByRoute) {
        const key = `draft-${this.conversationIdByRoute}-${this.replyType}`;
        this.$store.dispatch('draftMessages/delete', { key });
      }
    },
    saveDraft(conversationId, replyType) {
      if (this.message || this.message === '') {
        const key = `draft-${conversationId}-${replyType}`;
        const draftToSave = trimContent(this.message || '');

        this.$store.dispatch('draftMessages/set', {
          key,
          message: draftToSave,
        });
      }
    },
    setToDraft(conversationId, replyType) {
      this.saveDraft(conversationId, replyType);
      this.message = '';
    },
  },
};
