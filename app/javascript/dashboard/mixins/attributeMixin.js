import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
    }),
    attributes() {
      return this.$store.getters['attributes/getAttributesByModel'](
        'conversation_attribute'
      );
    },
    customAttributes() {
      return this.currentChat.custom_attributes || {};
    },
    conversationId() {
      return this.currentChat.id;
    },
    // Select only custom attribute which are already defined
    filteredAttributes() {
      return Object.keys(this.customAttributes)
        .filter(key => {
          return this.attributes.find(item => item.attribute_key === key);
        })
        .map(key => {
          const item = this.attributes.find(
            attribute => attribute.attribute_key === key
          );
          return {
            ...item,
            value: this.customAttributes[key],
            icon: this.attributeIcon(item.attribute_display_type),
          };
        });
    },
  },
  methods: {
    attributeIcon(attributeType) {
      switch (attributeType) {
        case 'date':
          return 'ion-calendar';
        case 'link':
          return 'ion-link';
        case 'currency':
          return 'ion-social-usd';
        case 'number':
          return 'ion-calculator';
        case 'percent':
          return 'ion-calculator';
        default:
          return 'ion-edit';
      }
    },
  },
};
