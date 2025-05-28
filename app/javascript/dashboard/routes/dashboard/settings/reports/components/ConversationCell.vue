<script setup>
const { row } = defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const routerParams = {
  name: 'inbox_conversation',
  params: { conversation_id: row.original.conversationId },
};
</script>

<template>
  <div class="text-right">
    <router-link :to="routerParams" class="hover:underline">
      {{ `#${row.original.conversationId}` }}
    </router-link>
    <div
      v-tooltip="row.original.createdAt"
      class="text-slate-600 dark:text-slate-200 text-sm"
    >
      {{ row.original.createdAgo }}
    </div>
  </div>
</template>
