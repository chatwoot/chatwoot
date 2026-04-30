<script setup>
import { ref, nextTick, computed, onMounted, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  column: {
    type: Object,
    required: true,
  },
  storeModule: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['deleted']);
const store = useStore();
const { t } = useI18n();

const isEditing = ref(props.column.is_new);
const newName = ref(props.column.name);
const inputRef = ref(null);
const showDeleteModal = ref(false);
const scrollContainerRef = ref(null);
const sentinelRef = ref(null);
let observer = null;

const isLoading = computed(() =>
  store.getters[`${props.storeModule}/isColumnLoading`](props.column.id)
);

const pagination = computed(() =>
  store.getters[`${props.storeModule}/getColumnPagination`](props.column.id)
);

const localItems = computed({
  get: () => props.column.items || [],
  set: () => {},
});

const isLoadingMore = computed(() => pagination.value.isLoadingMore ?? false);
const hasMore = computed(() => pagination.value.hasMore ?? false);
const displayCount = computed(
  () => pagination.value.totalCount ?? localItems.value.length
);

const setupObserver = () => {
  if (!sentinelRef.value) return;

  observer = new IntersectionObserver(
    entries => {
      if (entries[0].isIntersecting && hasMore.value && !isLoadingMore.value) {
        store.dispatch(
          `${props.storeModule}/fetchMoreColumnItems`,
          props.column.id
        );
      }
    },
    { root: scrollContainerRef.value, threshold: 0.1 }
  );

  observer.observe(sentinelRef.value);
};

onMounted(async () => {
  if (props.column.id && !props.column.itemsLoaded) {
    store.dispatch(`${props.storeModule}/fetchColumnItems`, props.column.id);
  }
  await nextTick();
  setupObserver();
});

onUnmounted(() => {
  observer?.disconnect();
});

const saveName = async () => {
  if (props.column.is_new && newName.value.trim() === '') {
    isEditing.value = false;
    emit('deleted', props.column);
    return;
  }

  if (newName.value.trim() === '' || newName.value === props.column.name) {
    isEditing.value = false;
    return;
  }

  if (props.column.id) {
    await store.dispatch(`${props.storeModule}/updateColumn`, {
      id: props.column.id,
      name: newName.value,
    });
  } else {
    emit('deleted', props.column);
    await store.dispatch(`${props.storeModule}/createColumn`, newName.value);
  }

  isEditing.value = false;
};

const startEditing = async () => {
  isEditing.value = true;
  newName.value = props.column.name;
  await nextTick();
  inputRef.value?.select();
};

const openDeleteModal = () => {
  if (localItems.value.length > 0) {
    useAlert(t('PIPELINE.DELETE_WITH_ITEMS'));
    return;
  }
  showDeleteModal.value = true;
};

const confirmDeletion = async () => {
  try {
    await store.dispatch(`${props.storeModule}/deleteColumn`, props.column.id);
    useAlert(t('PIPELINE.DELETE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.DELETE_FAILED'));
  }
  showDeleteModal.value = false;
};

const onDragEnd = event => {
  const toColumnId = parseInt(
    event.to.parentElement.parentElement.dataset.columnId,
    10
  );
  const itemId = parseInt(event.item.dataset.itemId, 10);
  const fromColumnId = props.column.id;

  if (toColumnId && itemId && toColumnId !== fromColumnId) {
    store.dispatch(`${props.storeModule}/moveItem`, {
      itemId,
      fromColumnId,
      toColumnId,
    });
  }
};
</script>

<template>
  <div class="flex flex-col flex-shrink-0 w-72" :data-column-id="column.id">
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :on-close="() => (showDeleteModal = false)"
      :on-confirm="confirmDeletion"
      :title="t('PIPELINE.DELETE_CONFIRMATION.TITLE')"
      :message="t('PIPELINE.DELETE_CONFIRMATION.MESSAGE')"
      :confirm-text="t('PIPELINE.DELETE_CONFIRMATION.DELETE')"
      :reject-text="t('PIPELINE.DELETE_CONFIRMATION.CANCEL')"
    />

    <div
      class="flex items-center justify-between flex-shrink-0 h-10 px-2 bg-n-solid-3 outline outline-n-container outline-1 -outline-offset-1 rounded-xl pl-3 pr-0"
    >
      <span
        class="column-drag-handle flex items-center mr-1 cursor-grab text-n-slate-9 hover:text-n-slate-11"
      >
        <i class="i-lucide-grip-vertical text-base" />
      </span>

      <span
        v-if="!isEditing"
        class="block text-sm font-semibold capitalize flex-1"
        @click="startEditing"
      >
        {{ column.name }}
        <span>({{ displayCount }})</span>
      </span>

      <input
        v-else
        ref="inputRef"
        v-model="newName"
        class="flex-1 text-sm font-semibold capitalize bg-transparent focus:outline-none"
        autoFocus
        @keyup.enter="saveName"
        @blur="saveName"
      />

      <Button slate icon="i-lucide-x" @click="openDeleteModal" />
    </div>

    <div ref="scrollContainerRef" class="max-h-[84vh] overflow-auto relative">
      <div v-if="isLoading" class="flex justify-center py-4">
        <span class="text-sm text-n-slate-11">{{ t('PIPELINE.LOADING') }}</span>
      </div>

      <p
        v-else-if="!localItems.length"
        class="flex items-center justify-center p-4 text-sm text-n-slate-11"
      >
        {{ t('PIPELINE.COLUMN.EMPTY') }}
      </p>

      <draggable
        v-model="localItems"
        group="pipeline-items"
        item-key="id"
        class="min-h-[79vh]"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div :data-item-id="element.id">
            <slot name="card" :item="element" />
          </div>
        </template>
      </draggable>

      <div ref="sentinelRef" class="h-1" />

      <p v-if="isLoadingMore" class="p-3 text-center text-sm text-n-slate-11">
        {{ t('PIPELINE.LOADING') }}
      </p>

      <p
        v-else-if="!hasMore && localItems.length > 0"
        class="p-4 text-center text-n-slate-11"
      >
        {{ t('PIPELINE.COLUMN.EOF') }}
      </p>
    </div>
  </div>
</template>
