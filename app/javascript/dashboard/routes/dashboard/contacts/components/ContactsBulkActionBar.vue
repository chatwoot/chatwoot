<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LabelActions from 'dashboard/components/widgets/conversation/conversationBulkActions/LabelActions.vue';

const props = defineProps({
  visibleContactIds: {
    type: Array,
    default: () => [],
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['clearSelection', 'assignLabels', 'toggleAll']);

const { t } = useI18n();

const selectedCount = computed(() => props.selectedContactIds.length);
const totalVisibleContacts = computed(() => props.visibleContactIds.length);
const showLabelSelector = ref(false);

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
  showLabelSelector.value = false;
  emit('clearSelection');
};

const toggleLabelSelector = () => {
  if (!selectedCount.value) return;
  showLabelSelector.value = !showLabelSelector.value;
};

const closeLabelSelector = () => {
  showLabelSelector.value = false;
};

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
  closeLabelSelector();
};

watch(selectedCount, count => {
  if (!count) {
    showLabelSelector.value = false;
  }
});
</script>

<template>
  <BulkSelectBar
    v-model="selectionModel"
    :all-items="allItems"
    :select-all-label="selectAllLabel"
    :selected-count-label="selectedCountLabel"
    class="w-full"
  >
    <template #secondary-actions>
      <Button
        size="sm"
        variant="ghost"
        color="slate"
        :label="t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION')"
        class="!px-3"
        @click="emitClearSelection"
      />
    </template>
    <template #actions>
      <div class="flex items-center gap-2 ml-auto">
        <div class="relative flex items-center">
          <Button
            size="sm"
            color="slate"
            variant="faded"
            icon="i-lucide-tags"
            :label="t('CONTACTS_BULK_ACTIONS.ASSIGN_LABELS')"
            :disabled="!selectedCount"
            class="min-w-[9rem]"
            @click="toggleLabelSelector"
          />
          <transition name="popover-animation">
            <LabelActions
              v-if="showLabelSelector"
              class="label-actions-box"
              @assign="handleAssignLabels"
              @close="closeLabelSelector"
            />
          </transition>
        </div>
      </div>
    </template>
  </BulkSelectBar>
</template>

<style scoped lang="scss">
.popover-animation-enter-active,
.popover-animation-leave-active {
  transition: transform ease-out 0.1s;
}

.popover-animation-enter {
  transform: scale(0.95);
  @apply opacity-0;
}

.popover-animation-enter-to {
  transform: scale(1);
  @apply opacity-100;
}

.popover-animation-leave {
  transform: scale(1);
  @apply opacity-100;
}

.popover-animation-leave-to {
  transform: scale(0.95);
  @apply opacity-0;
}

.label-actions-box {
  --triangle-position: 5.3125rem;
}
</style>
