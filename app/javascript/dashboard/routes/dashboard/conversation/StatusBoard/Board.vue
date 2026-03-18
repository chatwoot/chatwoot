<script setup>
import { onMounted, computed, ref } from 'vue';
import draggable from 'vuedraggable';
import Column from './Column.vue';
import { useStore } from 'vuex';
import AddColumn from './AddColumn.vue';
import Spinner from '../../../../components-next/spinner/Spinner.vue';

const store = useStore();
const newColumns = ref([]);

// =================== COMPUTED =================== //

const pipelineColumns = computed({
  get: () => store.getters['pipelineStatuses/getPipelineStatuses'] || [],
  set: orderedColumns => {
    store.dispatch(
      'pipelineStatuses/reorder',
      orderedColumns.map(c => c.id)
    );
  },
});

const columns = computed(() => [...pipelineColumns.value, ...newColumns.value]);

// =================== CALLBACKS =================== //

onMounted(() => {
  const alreadyLoaded =
    store.getters['pipelineStatuses/getPipelineStatuses']?.length > 0;

  if (!alreadyLoaded) {
    store.dispatch('pipelineStatuses/get');
  }
});

// =================== Emits =================== //

const addColumn = () => {
  newColumns.value.push({
    id: null,
    name: '',
    is_new: true,
  });
};

const deleteColumn = column => {
  newColumns.value = newColumns.value.filter(
    c => column.id && c.id !== column.id && c !== column
  );
};
</script>

<template>
  <div
    class="flex text-gray-700 bg-gradient-to-tr from-blue-200 via-indigo-200 to-pink-200"
  >
    <div v-if="columns?.length < 0" class="flex justify-center my-4">
      <Spinner class="text-n-brand" />
    </div>

    <div v-else class="flex flex-grow px-10 mt-4 space-x-6">
      <draggable
        v-model="pipelineColumns"
        group="columns"
        item-key="id"
        handle=".column-drag-handle"
        class="flex space-x-6"
        :animation="150"
      >
        <template #item="{ element }">
          <Column :column="element" @deleted="deleteColumn" />
        </template>
      </draggable>
      <Column
        v-for="(column, index) in newColumns"
        :key="`new-${index}`"
        :column="column"
        @deleted="deleteColumn"
      />
      <AddColumn @new-column="addColumn" />
    </div>
  </div>
</template>
