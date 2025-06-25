<script setup>
import { computed } from 'vue';
const props = defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const routeName = computed(() => `${props.row.original.type}_reports_show`);
</script>

<template>
  <router-link
    :to="{ name: routeName, params: { id: row.original.id } }"
    class="text-n-slate-12 hover:underline"
  >
    {{ row.original.name }}
  </router-link>
</template>
