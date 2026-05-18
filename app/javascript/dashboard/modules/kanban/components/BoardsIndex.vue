<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';

const store   = useStore();
const router  = useRouter();
const boards  = computed(() => store.getters['kanban/boards']);
const loading = computed(() => store.getters['kanban/isLoading']);
const showNew = ref(false);
const newName = ref('');
const newDescription = ref('');

onMounted(() => store.dispatch('kanban/fetchBoards'));

const openBoard = id => {
  const accountId = router.currentRoute.value.params.accountId;
  router.push(`/app/accounts/${accountId}/kanban/${id}`);
};

const submitNew = async () => {
  if (!newName.value.trim()) return;
  await store.dispatch('kanban/createBoard', {
    name:        newName.value.trim(),
    description: newDescription.value.trim(),
  });
  showNew.value = false;
  newName.value = '';
  newDescription.value = '';
};
</script>

<template>
  <div class="kanban-boards-index">
    <header class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-semibold">Kanban Boards</h1>
      <button class="button success" @click="showNew = !showNew">
        + New Board
      </button>
    </header>

    <div v-if="showNew" class="bg-slate-50 dark:bg-slate-800 p-4 rounded mb-4">
      <input v-model="newName"        placeholder="Board name"  class="input mb-2 w-full" />
      <input v-model="newDescription" placeholder="Description" class="input mb-2 w-full" />
      <button class="button success small" @click="submitNew">Create</button>
      <button class="button clear small ml-2"  @click="showNew = false">Cancel</button>
    </div>

    <p v-if="loading">Loading…</p>
    <div v-else-if="boards.length === 0" class="text-slate-500">
      No boards yet. Create your first one.
    </div>

    <ul v-else class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <li
        v-for="b in boards"
        :key="b.id"
        class="border rounded p-4 cursor-pointer hover:shadow"
        @click="openBoard(b.id)"
      >
        <h3 class="font-semibold">{{ b.name }}</h3>
        <p class="text-sm text-slate-500">{{ b.description }}</p>
        <p class="text-xs text-slate-400 mt-2">
          {{ b.columns_count }} columns · {{ b.cards_count }} cards
        </p>
      </li>
    </ul>
  </div>
</template>
