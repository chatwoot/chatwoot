import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
    }),
    allAttributes() {
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
    attributes() {
      return this.allAttributes.filter(
        item => !Object.keys(this.customAttributes).includes(item.attribute_key)
      );
    },
    filteredAttributes() {
      const customAttributes = [];
      Object.keys(this.customAttributes).filter(key => {
        const value = this.customAttributes[key];
        const itemExist = this.allAttributes.find(
          item => item.attribute_key === key
        );
        if (itemExist) {
          customAttributes.push({
            key,
            value,
            ...itemExist,
            icon: this.attributeIcon(itemExist.attribute_display_type),
          });
        }
      });
      return customAttributes;
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
