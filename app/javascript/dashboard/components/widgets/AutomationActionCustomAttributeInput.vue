<template>
  <div class="custom-attribute-input">
    <div class="custom-attribute-input__row">
      <div class="multiselect-wrap--small custom-attribute-input__select">
        <multiselect
          v-model="selectedAttribute"
          track-by="attribute_key"
          label="attribute_display_name"
          :placeholder="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_PLACEHOLDER')"
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :max-height="160"
          :options="filteredAttributes"
          :allow-empty="false"
          @input="onAttributeChange"
        />
      </div>
      <div class="custom-attribute-input__value">
        <input
          v-if="isTextInput"
          v-model="attributeValue"
          type="text"
          class="custom-attribute-input__text"
          :placeholder="
            $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
          "
          @input="updateValue"
        />
        <input
          v-else-if="isNumberInput"
          v-model.number="attributeValue"
          type="number"
          class="custom-attribute-input__text"
          :placeholder="
            $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
          "
          @input="updateValue"
        />
        <input
          v-else-if="isDateInput"
          v-model="attributeValue"
          type="date"
          class="custom-attribute-input__text"
          @input="updateValue"
        />
        <multiselect
          v-else-if="isListInput"
          v-model="selectedListValue"
          track-by="id"
          label="name"
          :placeholder="$t('FORMS.MULTISELECT.SELECT')"
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :max-height="160"
          :options="listOptions"
          :allow-empty="false"
          @input="onListValueChange"
        />
        <multiselect
          v-else-if="isCheckboxInput"
          v-model="selectedBooleanValue"
          track-by="id"
          label="name"
          :placeholder="$t('FORMS.MULTISELECT.SELECT')"
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :max-height="160"
          :options="booleanOptions"
          :allow-empty="false"
          @input="onBooleanValueChange"
        />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    // Value can be an object {attribute_key, attribute_value} or an array (when reset)
    value: {
      type: [Object, Array],
      default: () => ({}),
    },
    customAttributes: {
      type: Array,
      default: () => [],
    },
    attributeType: {
      type: String,
      default: 'contact_attribute',
    },
  },
  data() {
    return {
      selectedAttribute: null,
      attributeValue: '',
      selectedListValue: null,
      selectedBooleanValue: null,
      booleanOptions: [
        { id: true, name: 'True' },
        { id: false, name: 'False' },
      ],
    };
  },
  computed: {
    // Normalize value to always be an object
    normalizedValue() {
      if (Array.isArray(this.value)) {
        return this.value[0] || {};
      }
      return this.value || {};
    },
    filteredAttributes() {
      return this.customAttributes.filter(
        attr => attr.attribute_model === this.attributeType
      );
    },
    selectedAttributeType() {
      if (!this.selectedAttribute) return null;
      return this.selectedAttribute.attribute_display_type;
    },
    isTextInput() {
      return (
        this.selectedAttributeType === 'text' ||
        this.selectedAttributeType === 'link'
      );
    },
    isNumberInput() {
      return (
        this.selectedAttributeType === 'number' ||
        this.selectedAttributeType === 'currency' ||
        this.selectedAttributeType === 'percent'
      );
    },
    isDateInput() {
      return this.selectedAttributeType === 'date';
    },
    isListInput() {
      return this.selectedAttributeType === 'list';
    },
    isCheckboxInput() {
      return this.selectedAttributeType === 'checkbox';
    },
    listOptions() {
      if (!this.selectedAttribute || !this.selectedAttribute.attribute_values) {
        return [];
      }
      return this.selectedAttribute.attribute_values.map(val => ({
        id: val,
        name: val,
      }));
    },
  },
  mounted() {
    this.initializeFromValue();
  },
  methods: {
    initializeFromValue() {
      const val = this.normalizedValue;
      if (!val || !val.attribute_key) return;

      const attribute = this.filteredAttributes.find(
        attr => attr.attribute_key === val.attribute_key
      );
      if (attribute) {
        this.selectedAttribute = attribute;
        const attrValue = val.attribute_value;

        if (this.isListInput) {
          this.selectedListValue = { id: attrValue, name: attrValue };
        } else if (this.isCheckboxInput) {
          this.selectedBooleanValue = this.booleanOptions.find(
            opt => opt.id === attrValue
          );
        } else {
          this.attributeValue = attrValue;
        }
      }
    },
    onAttributeChange() {
      this.attributeValue = '';
      this.selectedListValue = null;
      this.selectedBooleanValue = null;
      this.updateValue();
    },
    onListValueChange() {
      this.attributeValue = this.selectedListValue
        ? this.selectedListValue.id
        : '';
      this.updateValue();
    },
    onBooleanValueChange() {
      this.attributeValue = this.selectedBooleanValue
        ? this.selectedBooleanValue.id
        : '';
      this.updateValue();
    },
    updateValue() {
      if (!this.selectedAttribute) return;

      this.$emit('input', {
        attribute_key: this.selectedAttribute.attribute_key,
        attribute_value: this.attributeValue,
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.custom-attribute-input {
  @apply w-full mt-2;

  &__row {
    @apply flex gap-2;
  }

  &__select {
    @apply flex-1;
  }

  &__value {
    @apply flex-1;
  }

  &__text {
    @apply mb-0 w-full;
  }
}

.multiselect {
  @apply mb-0;
}
</style>
