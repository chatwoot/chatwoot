import { mapGetters } from 'vuex';
import { isValidURL } from '../helper/URLHelper';
export default {
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
    }),
    attributes() {
      return this.$store.getters['attributes/getAttributesByModel'](
        this.attributeType
      );
    },
    contactIdentifier() {
      return (
        this.currentChat.meta?.sender?.id ||
        this.$route.params.contactId ||
        this.contactId
      );
    },
    conversationId() {
      return this.currentChat.id;
    },
  },
  methods: {
    isAttributeNumber(attributeValue) {
      return (
        Number.isInteger(Number(attributeValue)) && Number(attributeValue) > 0
      );
    },
    attributeDisplayType(attributeValue) {
      if (this.isAttributeNumber(attributeValue)) {
        return 'number';
      }
      if (isValidURL(attributeValue)) {
        return 'link';
      }
      return 'text';
    },
  },
};
