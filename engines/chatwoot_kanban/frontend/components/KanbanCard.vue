<script setup>
import { computed, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import CardModal from './CardModal.vue';

const props = defineProps({
  card: { type: Object, required: true },
});
const router    = useRouter();
const route     = useRoute();
const showModal = ref(false);

const priorityColor = computed(() => ({
  priority_low:    'bg-slate-100 text-slate-700',
  priority_medium: 'bg-blue-100 text-blue-700',
  priority_high:   'bg-orange-100 text-orange-700',
  priority_urgent: 'bg-red-100 text-red-700',
}[`priority_${props.card.priority}`] || 'bg-slate-100 text-slate-700'));

const onDragStart = e => {
  e.dataTransfer.setData('cardId', String(props.card.id));
  e.dataTransfer.effectAllowed = 'move';
};

const goToConversation = () => {
  if (!props.card.conversation_id) return;
  const accountId = route.params.accountId;
  router.push(`/app/accounts/${accountId}/conversations/${props.card.conversation_id}`);
};
</script>

<template>
  <article
    draggable="true"
    @dragstart="onDragStart"
    @click="showModal = true"
    class="kanban-card border rounded p-2 bg-white dark:bg-slate-700 cursor-grab hover:shadow"
  >
    <div v-if="(card.labels || []).length" class="flex gap-1 mb-1">
      <span v-for="l in card.labels" :key="l.id"
            class="text-[10px] px-1.5 py-0.5 rounded text-white"
            :style="{ background: l.color }">{{ l.name }}</span>
    </div>

    <header class="flex justify-between items-start gap-2">
      <h4 class="text-sm font-medium flex-1">{{ card.title }}</h4>
      <span class="text-[10px] px-1.5 py-0.5 rounded" :class="priorityColor">
        {{ card.priority }}
      </span>
    </header>

    <p v-if="card.description" class="text-xs text-slate-500 mt-1 line-clamp-2">
      {{ card.description }}
    </p>

    <footer class="flex items-center justify-between mt-2 text-[11px] text-slate-400">
      <span class="flex items-center gap-2">
        <span v-if="card.due_at">📅 {{ new Date(card.due_at).toLocaleDateString() }}</span>
        <span v-if="card.checklist_total">☑ {{ card.checklist_progress }}%</span>
        <span v-if="card.comments_count">💬 {{ card.comments_count }}</span>
      </span>
      <button
        v-if="card.conversation_id"
        class="text-blue-500 hover:underline"
        @click.stop="goToConversation"
      >
        #{{ card.conversation?.display_id || card.conversation_id }}
      </button>
    </footer>

    <Teleport to="body">
      <CardModal v-if="showModal" :card="card" @close="showModal = false" />
    </Teleport>
  </article>
</template>
