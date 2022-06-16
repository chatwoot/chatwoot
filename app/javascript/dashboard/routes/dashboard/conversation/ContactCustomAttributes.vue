<template>
  <div class="custom-attributes--panel">
    <div
      v-for="attribute in listOfAttributes"
      :key="attribute"
      class="custom-attribute--row"
    >
      <div class="custom-attribute--row__attribute">
        {{ attribute }}
      </div>
      <div>
        <span v-dompurify-html="valueWithLink(customAttributes[attribute])" />
      </div>
    </div>
    <p v-if="!listOfAttributes.length">
      {{ $t('CUSTOM_ATTRIBUTES.NOT_AVAILABLE') }}
    </p>
  </div>
</template>

<script>
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

export default {
  props: {
    customAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    listOfAttributes() {
      return Object.keys(this.customAttributes).filter(key => {
        const value = this.customAttributes[key];
        return value !== null && value !== undefined && value !== '';
      });
    },
  },
  methods: {
    valueWithLink(attribute) {
      const parsedAttribute = this.parseAttributeToString(attribute);
      const messageFormatter = new MessageFormatter(parsedAttribute);
      return messageFormatter.formattedMessage;
    },
    parseAttributeToString(attribute) {
      switch (typeof attribute) {
        case 'string':
          return attribute;
        case 'object':
          return JSON.stringify(attribute);
        default:
          return `${attribute}`;
      }
    },
  },
};
</script>

<style scoped>
.custom-attributes--panel {
  margin-bottom: var(--space-normal);
}

.custom-attribute--row__attribute {
  font-weight: 500;
}
</style>
