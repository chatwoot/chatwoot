<script setup>
import { computed } from 'vue';

const props = defineProps({
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  currentAccountId: {
    type: Number,
    required: true,
  },
});

const citations = computed(() => {
  const items = props.contentAttributes?.items || [];
  const citationItem = items.find(item => item.name === 'citations');
  return citationItem?.data ?? [];
});

// TODO: once we have datasource child document page, we can refactor this to go there
const documentsUrl = computed(() => {
  return `/app/accounts/${props.currentAccountId}/aiagent/documents`;
});
</script>

<template>
  <div class="citation-container text-xs text-n-500">
    <div class="flex flex-wrap gap-x-2">
      <div
        v-for="(citation, index) in citations"
        :key="citation.id"
        class="citation-item"
      >
        <a
          :href="documentsUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="hover:text-n-800 transition-colors"
        >
          [{{ index + 1 }}] {{ citation.content }}
        </a>
      </div>
    </div>
  </div>
</template>

<style scoped>
.citation-container {
  margin-top: 0.25rem;
  padding-left: 0.25rem;
}

.citation-item {
  display: inline-block;
}
</style>
