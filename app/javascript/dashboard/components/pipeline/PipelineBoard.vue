<script setup>
import { onMounted, computed, ref } from 'vue';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import PipelineColumn from './PipelineColumn.vue';
import PipelineAddColumn from './PipelineAddColumn.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  storeModule: {
    type: String,
    required: true,
  },
});

const store = useStore();
const newColumns = ref([]);

const allColumns = computed(() => store.getters[`${props.storeModule}/getColumns`] || []);

const reorderableColumns = computed({
  get: () => allColumns.value,
  set: orderedColumns => {
    store.dispatch(
      `${props.storeModule}/reorderColumns`,
      orderedColumns.map(c => c.id)
    );
  },
});

const isFetching = computed(
  () => store.getters[`${props.storeModule}/getUiFlags`].isFetchingColumns
);

onMounted(() => {
  if (!allColumns.value.length) {
    store.dispatch(`${props.storeModule}/fetchColumns`);
  }
});

const addColumn = () => {
  newColumns.value.push({ id: null, name: '', is_new: true, items: [] });
};

const deleteColumn = column => {
  newColumns.value = newColumns.value.filter(
    c => (column.id ? c.id !== column.id : c !== column)
  );
};
</script>

<template>
  <div
    class="flex text-gray-700 bg-gradient-to-tr from-blue-200 via-indigo-200 to-pink-200 min-h-full"
  >
    <div v-if="isFetching" class="flex justify-center items-center w-full py-10">
      <Spinner class="text-n-brand" />
    </div>

    <div v-else class="flex flex-grow px-10 mt-4 space-x-6">
      <draggable
        v-model="reorderableColumns"
        group="pipeline-columns"
        item-key="id"
        handle=".column-drag-handle"
        class="flex space-x-6"
        :animation="150"
      >
        <template #item="{ element }">
          <PipelineColumn
            :column="element"
            :store-module="storeModule"
            @deleted="deleteColumn"
          >
            <template #card="{ item }">
              <slot name="card" :item="item" />
            </template>
          </PipelineColumn>
        </template>
      </draggable>

      <PipelineColumn
        v-for="(col, index) in newColumns"
        :key="`new-${index}`"
        :column="col"
        :store-module="storeModule"
        @deleted="deleteColumn"
      >
        <template #card="{ item }">
          <slot name="card" :item="item" />
        </template>
      </PipelineColumn>

      <PipelineAddColumn :store-module="storeModule" @new-column="addColumn" />
    </div>
  </div>
</template>
