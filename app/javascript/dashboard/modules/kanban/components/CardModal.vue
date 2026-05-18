<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';

const props = defineProps({
  card: { type: Object, required: true },
});
const emit = defineEmits(['close']);
const store = useStore();

const tab        = ref('detail');         // detail | comments | checklist | labels
const comments   = ref([]);
const newComment = ref('');
const newItem    = ref('');
const allLabels  = computed(() => store.getters['kanban/labels']);

const loadComments = async () => {
  comments.value = await store.dispatch('kanban/fetchComments', props.card.id);
};
onMounted(loadComments);
watch(() => props.card.id, loadComments);

const submitComment = async () => {
  if (!newComment.value.trim()) return;
  await store.dispatch('kanban/addComment', { cardId: props.card.id, content: newComment.value });
  newComment.value = '';
  await loadComments();
};

const addItem = async () => {
  if (!newItem.value.trim()) return;
  await store.dispatch('kanban/addChecklistItem', { cardId: props.card.id, title: newItem.value });
  newItem.value = '';
};

const toggleItem = async itemId =>
  store.dispatch('kanban/toggleChecklistItem', { cardId: props.card.id, itemId });

const toggleLabel = async label => {
  const has = (props.card.labels || []).some(l => l.id === label.id);
  if (has) await store.dispatch('kanban/unassignLabel', { cardId: props.card.id, labelId: label.id });
  else     await store.dispatch('kanban/assignLabel',   { cardId: props.card.id, labelId: label.id });
};
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="emit('close')">
    <div class="bg-white dark:bg-slate-800 w-[640px] max-h-[85vh] overflow-y-auto rounded shadow-lg">
      <header class="px-4 py-3 border-b flex justify-between items-center">
        <h2 class="font-semibold text-lg">{{ card.title }}</h2>
        <button class="text-slate-400 hover:text-slate-700" @click="emit('close')">&times;</button>
      </header>

      <nav class="flex border-b text-sm">
        <button v-for="t in ['detail','comments','checklist','labels']"
                :key="t"
                :class="['px-4 py-2 capitalize', tab === t ? 'border-b-2 border-blue-500 font-medium' : 'text-slate-500']"
                @click="tab = t">
          {{ t }}
          <span v-if="t === 'comments'" class="ml-1 text-xs">({{ comments.length }})</span>
          <span v-else-if="t === 'checklist' && card.checklist_total" class="ml-1 text-xs">
            ({{ card.checklist_progress }}%)
          </span>
          <span v-else-if="t === 'labels' && card.labels?.length" class="ml-1 text-xs">
            ({{ card.labels.length }})
          </span>
        </button>
      </nav>

      <section class="p-4">
        <!-- detail -->
        <div v-if="tab === 'detail'">
          <p class="text-sm text-slate-600 whitespace-pre-line">{{ card.description || '—' }}</p>
          <dl class="mt-4 text-xs text-slate-500 space-y-1">
            <div><dt class="inline font-semibold">Priority:</dt> <dd class="inline">{{ card.priority }}</dd></div>
            <div v-if="card.due_at"><dt class="inline font-semibold">Due:</dt>
              <dd class="inline">{{ new Date(card.due_at).toLocaleString() }}</dd></div>
            <div v-if="card.conversation_id"><dt class="inline font-semibold">Conversation:</dt>
              <dd class="inline">#{{ card.conversation?.display_id || card.conversation_id }}</dd></div>
          </dl>
        </div>

        <!-- comments -->
        <div v-else-if="tab === 'comments'">
          <ul class="space-y-2 mb-3">
            <li v-for="c in comments" :key="c.id" class="border rounded p-2">
              <div class="text-xs text-slate-500">user #{{ c.author_id }} · {{ new Date(c.created_at).toLocaleString() }}</div>
              <div class="text-sm whitespace-pre-line">{{ c.content }}</div>
            </li>
          </ul>
          <div class="flex gap-1">
            <input v-model="newComment" class="input flex-1" placeholder="Write a comment… use @123 to mention user 123"
                   @keydown.enter="submitComment" />
            <button class="button success small" @click="submitComment">Post</button>
          </div>
        </div>

        <!-- checklist -->
        <div v-else-if="tab === 'checklist'">
          <ul class="space-y-1 mb-3">
            <li v-for="item in (card.checklist_items || [])" :key="item.id"
                class="flex items-center gap-2 text-sm">
              <input type="checkbox" :checked="item.completed" @change="toggleItem(item.id)" />
              <span :class="{ 'line-through text-slate-400': item.completed }">{{ item.title }}</span>
            </li>
          </ul>
          <div class="flex gap-1">
            <input v-model="newItem" class="input flex-1" placeholder="Add checklist item"
                   @keydown.enter="addItem" />
            <button class="button success small" @click="addItem">+</button>
          </div>
        </div>

        <!-- labels -->
        <div v-else-if="tab === 'labels'">
          <p v-if="allLabels.length === 0" class="text-xs text-slate-500">
            No labels defined for this account yet. Create one in Settings → Kanban Labels.
          </p>
          <ul v-else class="space-y-1">
            <li v-for="label in allLabels" :key="label.id"
                class="flex items-center gap-2 text-sm cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 p-1 rounded"
                @click="toggleLabel(label)">
              <input type="checkbox" :checked="(card.labels || []).some(l => l.id === label.id)" />
              <span class="inline-block w-3 h-3 rounded" :style="{ background: label.color }"></span>
              {{ label.name }}
            </li>
          </ul>
        </div>
      </section>
    </div>
  </div>
</template>
