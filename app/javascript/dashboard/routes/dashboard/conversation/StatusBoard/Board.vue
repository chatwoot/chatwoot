<script setup>
import { onMounted, computed, ref } from 'vue';
import Column from './Column.vue';
import { useStore } from 'vuex';
import AddColumn from './AddColumn.vue';
import Spinner from '../../../../components-next/spinner/Spinner.vue';

const store = useStore();
const newColumns = ref([]);

// =================== COMPUTED =================== //

const columns = computed(() => {
  const pipelineStatuses =
    store.getters['pipelineStatuses/getPipelineStatuses'] || [];
  return [...pipelineStatuses, ...newColumns.value];
});

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
      <Column
        v-for="(column, index) in columns"
        :key="index"
        :column="column"
        @deleted="deleteColumn"
      />
      <AddColumn @new-column="addColumn" />
    </div>
  </div>
</template>
