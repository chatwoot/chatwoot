<template>
  <div class="custom-attributes--panel">
    <custom-attribute
      v-for="attribute in attributes"
      :key="attribute.id"
      :attribute-key="attribute.key"
      :attribute-type="attribute.attribute_display_type"
      :label="attribute.attribute_display_name"
      icon="ion-document-text"
      emoji=""
      :value="attribute.value"
      :show-edit="true"
      @update="onUpdate"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    CustomAttribute,
  },
  mixins: [alertMixin],
  props: {
    customAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    attributes() {
      const attributes = this.$store.getters['attributes/getAttributesByModel'](
        'conversation_attribute'
      );
      const customAttributes = [];
      Object.keys(this.customAttributes).filter(key => {
        const value = this.customAttributes[key];
        const itemExist = attributes.find(item => item.attribute_key === key);
        if (itemExist) {
          customAttributes.push({ key, value, ...itemExist });
        }
      });
      return customAttributes;
    },
  },
  methods: {
    async onUpdate(key, value) {
      try {
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.currentChat.id,
          customAttributes: { [key]: value },
        });
        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.UPDATE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.UPDATE.SUCCESS');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>

<style scoped>
.custom-attributes--panel {
  margin-bottom: var(--space-normal);
}

.conv-details--item {
  padding-bottom: 0;
}

.custom-attribute--row__attribute {
  font-weight: 500;
}
</style>
