import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
    }),
    customAttributes() {
      return this.currentChat.custom_attributes || {};
    },
    conversationId() {
      return this.currentChat.id;
    },
    allAttributes() {
      return this.$store.getters['attributes/getAttributesByModel'](
        this.attributeType
      ).map(item => ({
        id: item.id,
        title: item.attribute_display_name,
        attribute_key: item.attribute_key,
        icon: this.attributeIcon(item.attribute_display_type),
      }));
    },
    attributes() {
      return this.allAttributes.filter(
        item => !Object.keys(this.customAttributes).includes(item.attribute_key)
      );
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
