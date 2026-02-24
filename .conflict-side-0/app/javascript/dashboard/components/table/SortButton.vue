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
  <span :class="sortIconMap[header.column.getIsSorted() || 'default']" />
</template>
