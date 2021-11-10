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
      :show-actions="true"
      :class="attributeClass"
      @update="onUpdate"
      @delete="onDelete"
      @copy="onCopy"
    />
  </div>
</template>

<script>
import copy from 'copy-text-to-clipboard';
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
    attributeClass: {
      type: String,
      default: '',
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
    onCopy(attributeValue) {
      copy(attributeValue);
      this.showAlert(this.$t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
    },
  },
};
</script>
<style scoped lang="scss">
.custom-attributes--panel {
  .conversation--attribute {
    border-bottom: 1px solid var(--color-border-light);
  }

  &.odd {
    .conversation--attribute {
      &:nth-child(2n + 1) {
        background: var(--b-50);
      }
    }
  }

  &.even {
    .conversation--attribute {
      &:nth-child(2n) {
        background: var(--b-50);
      }
    }
  }
}
</style>
