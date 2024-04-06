<script setup>
import FilterListItemButton from './FilterListItemButton.vue';

defineProps({
  listItems: {
    type: Array,
    default: () => [],
  },
});
</script>
<template>
  <div
    class="z-20 w-40 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50"
  >
    <slot name="search" />
    <slot name="listItem" />
    <filter-list-item-button
      v-for="item in listItems"
      :key="item.id"
      :button-text="item.name"
      @click="$emit('click')"
    />
  </div>
</template>
