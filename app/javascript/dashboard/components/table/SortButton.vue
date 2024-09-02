<script setup>
defineProps({
  header: {
    type: Object,
    required: true,
  },
});

const sortIconMap = {
  default: 'i-lucide-chevrons-up-down',
  asc: 'i-lucide-chevron-up',
  desc: 'i-lucide-chevron-down',
};
</script>

<template>
  <button class="sort-btn">
    <span :class="sortIconMap[header.column.getIsSorted() || 'default']" />
  </button>
</template>
