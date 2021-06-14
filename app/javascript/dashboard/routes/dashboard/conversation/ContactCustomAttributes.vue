<template>
  <div class="custom-attributes--panel">
    <contact-details-item
      :title="$t('CUSTOM_ATTRIBUTES.TITLE')"
      icon="ion-code"
      emoji="📕"
    />
    <div
      v-for="attribute in listOfAttributes"
      :key="attribute"
      class="custom-attribute--row"
    >
      <div class="custom-attribute--row__attribute">
        {{ attribute }}
      </div>
      <div>
        {{ customAttributes[attribute] }}
      </div>
    </div>
  </div>
</template>

<script>
import ContactDetailsItem from './ContactDetailsItem.vue';

export default {
  components: {
    ContactDetailsItem,
  },
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
};
</script>

<style scoped>
.custom-attributes--panel {
  margin-bottom: var(--space-normal);
}

.conv-details--item {
  padding-bottom: 0;
}
.custom-attribute--row {
  margin-bottom: var(--space-small);
  margin-left: var(--space-medium);
}

.custom-attribute--row__attribute {
  font-weight: 500;
}
</style>
