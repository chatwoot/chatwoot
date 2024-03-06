<template>
  <div class="custom-attributes--panel">
    <custom-attribute
      v-for="attribute in displayedAttributes"
      :key="attribute.id"
      :attribute-key="attribute.attribute_key"
      :attribute-type="attribute.attribute_display_type"
      :values="attribute.attribute_values"
      :label="attribute.attribute_display_name"
      :icon="attribute.icon"
      emoji=""
      :value="attribute.value"
      :show-actions="true"
      :attribute-regex="attribute.regex_pattern"
      :regex-cue="attribute.regex_cue"
      :class="attributeClass"
      @update="onUpdate"
      @delete="onDelete"
      @copy="onCopy"
    />
    <!-- Show more and show less buttons show it if the filteredAttributes length is greater than 5 -->
    <div
      class="flex"
      :class="(addShowMoreButton || showAllAttributes) && 'px-2 py-2'"
    >
      <woot-button
        v-if="addShowMoreButton"
        size="small"
        icon="chevron-down"
        variant="clear"
        color-scheme="primary"
        class="!px-2 hover:!bg-transparent dark:hover:!bg-transparent"
        @click="showAllAttributes = true"
      >
        Show more attributes
      </woot-button>

      <woot-button
        v-if="showAllAttributes"
        size="small"
        color-scheme="primary"
        icon="chevron-up"
        variant="clear"
        class="!px-2 hover:!bg-transparent dark:hover:!bg-transparent"
        @click="showAllAttributes = false"
      >
        Show less attributes
      </woot-button>
    </div>
  </div>
</template>

<script>
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import alertMixin from 'shared/mixins/alertMixin';
import attributeMixin from 'dashboard/mixins/attributeMixin';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

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
    contactId: { type: Number, default: null },
  },
  data() {
    return {
      showAllAttributes: false,
    };
  },
  computed: {
    displayedAttributes() {
      // Show only the first 5 attributes or all depending on showAllAttributes
      if (this.showAllAttributes || this.filteredAttributes.length <= 5) {
        return this.filteredAttributes;
      }
      return this.filteredAttributes.slice(0, 5);
    },
    addShowMoreButton() {
      return this.filteredAttributes.length > 5 && !this.showAllAttributes;
    },
  },
  methods: {
    async onUpdate(key, value) {
      const updatedAttributes = { ...this.customAttributes, [key]: value };
      try {
        if (this.attributeType === 'conversation_attribute') {
          await this.$store.dispatch('updateCustomAttributes', {
            conversationId: this.conversationId,
            customAttributes: updatedAttributes,
          });
        } else {
          this.$store.dispatch('contacts/update', {
            id: this.contactId,
            custom_attributes: updatedAttributes,
          });
        }
        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
        this.showAlert(errorMessage);
      }
    },
    async onDelete(key) {
      try {
        const { [key]: remove, ...updatedAttributes } = this.customAttributes;
        if (this.attributeType === 'conversation_attribute') {
          await this.$store.dispatch('updateCustomAttributes', {
            conversationId: this.conversationId,
            customAttributes: updatedAttributes,
          });
        } else {
          this.$store.dispatch('contacts/deleteCustomAttributes', {
            id: this.contactId,
            customAttributes: [key],
          });
        }

        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
        this.showAlert(errorMessage);
      }
    },
    async onCopy(attributeValue) {
      await copyTextToClipboard(attributeValue);
      this.showAlert(this.$t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
    },
  },
};
</script>
<style scoped lang="scss">
.custom-attributes--panel {
  .conversation--attribute {
    @apply border-slate-50 dark:border-slate-700/50 border-b border-solid;
  }

  &.odd {
    .conversation--attribute {
      &:nth-child(2n + 1) {
        @apply bg-slate-25 dark:bg-slate-800/50;
      }
    }
  }

  &.even {
    .conversation--attribute {
      &:nth-child(2n) {
        @apply bg-slate-25 dark:bg-slate-800/50;
      }
    }
  }
}
</style>
