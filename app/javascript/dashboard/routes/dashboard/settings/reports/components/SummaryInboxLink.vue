<script setup>
defineProps({
  row: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <router-link
    :to="{ name: 'inbox_reports_show', params: { inboxId: row.original.id } }"
    class="text-n-slate-12 hover:underline"
  >
    {{ row.original.name }}
  </router-link>
</template>
