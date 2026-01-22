<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import BulkLabelActions from 'dashboard/components/widgets/conversation/conversationBulkActions/BulkLabelActions.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  visibleContactIds: {
    type: Array,
    default: () => [],
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'clearSelection',
  'assignLabels',
  'toggleAll',
  'deleteSelected',
]);

const { t } = useI18n();

const selectedCount = computed(() => props.selectedContactIds.length);
const totalVisibleContacts = computed(() => props.visibleContactIds.length);

const selectAllLabel = computed(() => {
  if (!totalVisibleContacts.value) {
    return '';
  }

  return t('CONTACTS_BULK_ACTIONS.SELECT_ALL', {
    count: totalVisibleContacts.value,
  });
});

const selectedCountLabel = computed(() =>
  t('CONTACTS_BULK_ACTIONS.SELECTED_COUNT', {
    count: selectedCount.value,
  })
);

const allItems = computed(() =>
  props.visibleContactIds.map(id => ({
    id,
  }))
);

const selectionModel = computed({
  get: () => new Set(props.selectedContactIds),
  set: newSet => {
    if (!props.visibleContactIds.length) {
      emit('toggleAll', false);
      return;
    }

    const shouldSelectAll =
      newSet.size === props.visibleContactIds.length && newSet.size > 0;
    emit('toggleAll', shouldSelectAll);
  },
});

const emitClearSelection = () => {
  emit('clearSelection');
};

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
};
</script>

<template>
  <BulkSelectBar
    v-model="selectionModel"
    :all-items="allItems"
    :select-all-label="selectAllLabel"
    :selected-count-label="selectedCountLabel"
    animation-direction="vertical"
    class="justify-between absolute bottom-20 left-1/2 -translate-x-1/2 z-30 lg:!w-[39rem] sm:!w-[calc(100%-6rem)] !w-[calc(100%-4rem)] max-w-4xl"
  >
    <template #secondary-actions>
      <Button
        sm
        ghost
        :label="t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION')"
        class="!px-1"
        @click="emitClearSelection"
      />
    </template>
    <template #actions>
      <div class="flex items-center gap-2 ml-auto">
        <BulkLabelActions
          type="contact"
          :is-loading="isLoading"
          :disabled="!selectedCount"
          class="[&>button]:!text-n-blue-11 [&>button>span]:!text-n-blue-11 [&>button]:!px-2"
          @assign="handleAssignLabels"
        />
        <div class="w-px h-3 bg-n-weak rounded-lg" />
        <Policy :permissions="['administrator']">
          <Button
            v-tooltip.bottom="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
            sm
            ghost
            ruby
            icon="i-lucide-trash"
            :label="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
            :aria-label="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
            :disabled="!selectedCount || isLoading"
            :is-loading="isLoading"
            class="!px-2 [&>span:nth-child(2)]:hidden md:[&>span:nth-child(2)]:inline-flex"
            @click="emit('deleteSelected')"
          />
        </Policy>
      </div>
    </template>
  </BulkSelectBar>
</template>
