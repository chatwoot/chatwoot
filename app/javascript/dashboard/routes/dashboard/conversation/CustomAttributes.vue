<template>
  <div class="custom-attributes--panel">
    <custom-attribute
      v-for="attribute in filteredAttributes"
      :key="attribute.id"
      :attribute-key="attribute.attribute_key"
      :attribute-type="attribute.attribute_display_type"
      :label="attribute.attribute_display_name"
      :icon="attribute.icon"
      emoji=""
      :value="attribute.value"
      :show-edit="true"
      @update="onUpdate"
      @delete="onDelete"
    />
  </div>
</template>

<script>
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import alertMixin from 'shared/mixins/alertMixin';
import attributeMixin from 'dashboard/mixins/attributeMixin';
export default {
  components: {
    CustomAttribute,
  },
  mixins: [alertMixin, attributeMixin],
  props: {
    attributeType: {
      type: String,
      default: 'conversation_attribute',
    },
  },
  methods: {
    async onUpdate(key, value) {
      try {
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.conversationId,
          customAttributes: { ...this.customAttributes, [key]: value },
        });
        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
        this.showAlert(errorMessage);
      }
    },
    async onDelete(key) {
      const { [key]: remove, ...updatedAttributes } = this.customAttributes;

      try {
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.conversationId,
          customAttributes: updatedAttributes,
        });
        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
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
