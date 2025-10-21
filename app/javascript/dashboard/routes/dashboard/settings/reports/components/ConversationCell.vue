<script setup>
import { computed } from 'vue';

const { row } = defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const routerParams = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: row.original.conversationId },
}));
</script>

<template>
  <div class="text-right">
    <router-link :to="routerParams" class="hover:underline">
      {{ `#${row.original.conversationId}` }}
    </router-link>
    <div v-tooltip="row.original.createdAt" class="text-n-slate-11 text-sm">
      {{ row.original.createdAgo }}
    </div>
  </div>
</template>
