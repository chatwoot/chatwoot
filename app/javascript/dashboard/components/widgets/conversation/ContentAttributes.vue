<template>
  <div v-if="hasContentAttributes" class="content-attributes-panel">
    <h3 class="content-attributes-title">
      {{ $t('CONVERSATION.CONTENT_ATTRIBUTES.TITLE') }}
    </h3>
    <div v-for="(value, key) in contentAttributes" :key="key" class="content-attribute">
      <span class="content-attribute-key">{{ formatKey(key) }}</span>
      <span class="content-attribute-value">{{ formatValue(value) }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ContentAttributes',
  props: {
    contentAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    hasContentAttributes() {
      return Object.keys(this.contentAttributes || {}).length > 0;
    },
  },
  methods: {
    formatKey(key) {
      return key
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
    },
    formatValue(value) {
      if (typeof value === 'object') {
        return JSON.stringify(value, null, 2);
      }
      return value;
    },
  },
};
</script>

<style lang="scss" scoped>
.content-attributes-panel {
  @apply p-4 mb-4 bg-n-gray-2 dark:bg-slate-900 rounded-md;
}

.content-attributes-title {
  @apply text-n-gray-12 dark:text-n-gray-0 text-sm font-medium mb-2;
}

.content-attribute {
  @apply flex justify-between py-1 border-b border-n-gray-3 dark:border-slate-800;
}

.content-attribute-key {
  @apply text-n-gray-8 dark:text-n-gray-2 text-sm font-medium;
}

.content-attribute-value {
  @apply text-n-gray-12 dark:text-n-gray-0 text-sm break-all text-right;
}
</style> 