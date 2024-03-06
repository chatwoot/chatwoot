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
    customAttributes() {
      if (this.attributeType === 'conversation_attribute')
        return this.currentChat.custom_attributes || {};
      return this.contact.custom_attributes || {};
    },
    contactIdentifier() {
      return (
        this.currentChat.meta?.sender?.id ||
        this.$route.params.contactId ||
        this.contactId
      );
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactIdentifier);
    },
    conversationId() {
      return this.currentChat.id;
    },
    filteredAttributes() {
      return this.attributes.map(attribute => {
        // Check if the attribute key exists in customAttributes
        const hasValue = Object.hasOwnProperty.call(
          this.customAttributes,
          attribute.attribute_key
        );

        const isCheckbox = attribute.attribute_display_type === 'checkbox';
        const defaultValue = isCheckbox ? false : '';

        return {
          ...attribute,
          // Set value from customAttributes if it exists, otherwise use default value
          value: hasValue
            ? this.customAttributes[attribute.attribute_key]
            : defaultValue,
        };
      });
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
