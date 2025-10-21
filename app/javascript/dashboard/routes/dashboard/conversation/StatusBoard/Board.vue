<script setup>
import { onMounted, ref, watchEffect } from 'vue';
import Column from './Column.vue';
import { useStore } from 'vuex';
import AddColumn from './AddColumn.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();
const columns = ref([]);

// =================== CALLBACKS =================== //

onMounted(() => {
  store.dispatch('pipelineStatuses/get');
});

watchEffect(() => {
  const pipelineStatuses =
    store.getters['pipelineStatuses/getPipelineStatuses'] || [];
  const conversations = props.modelValue || [];

  if (pipelineStatuses.length === 0) return;

  columns.value = pipelineStatuses.map(status => {
    const conversationsByCol = conversations.filter(
      conversation => conversation.pipeline_status_id === status.id
    );

    return {
      id: status.id,
      name: status.name,
      conversations: conversationsByCol,
      conversation_number: conversationsByCol.length,
      is_new: false,
    };
  });
});

// =================== Emits =================== //

const addColumn = () => {
  columns.value.push({
    id: null,
    name: '',
    conversation_number: 0,
    is_new: true,
  });
};

const deleteColumn = column => {
  columns.value = columns.value.filter(c => c.id !== column.id && c !== column);
};
</script>

<template>
  <div
    class="flex flex-col w-full h-full overflow-auto text-gray-700 bg-gradient-to-tr from-blue-200 via-indigo-200 to-pink-200"
  >
    <div class="flex flex-grow px-10 mt-4 space-x-6 overflow-auto">
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
