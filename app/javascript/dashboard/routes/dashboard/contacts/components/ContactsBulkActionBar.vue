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
  // Set on the Leads/Customers pages, where changing to the same type is pointless.
  contactType: {
    type: String,
    default: '',
  },
});

const emit = defineEmits([
  'clearSelection',
  'assignLabels',
  'removeLabels',
  'toggleAll',
  'deleteSelected',
  'changeContactType',
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

    const shouldSelectAll = props.visibleContactIds.every(id => newSet.has(id));
    emit('toggleAll', shouldSelectAll);
  },
});

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
};

const handleRemoveLabels = labels => {
  emit('removeLabels', labels);
};
</script>

<template>
  <div
    class="sticky top-0 z-10 bg-gradient-to-b from-n-surface-1 from-90% to-transparent pt-1 pb-2"
  >
    <BulkSelectBar
      v-model="selectionModel"
      :all-items="allItems"
      :select-all-label="selectAllLabel"
      :selected-count-label="selectedCountLabel"
      class="py-2 ltr:!pr-3 rtl:!pl-3 justify-between"
    >
      <template #primaryActions>
        <Button
          sm
          ghost
          slate
          :label="t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION')"
          class="!px-1"
          @click="emit('clearSelection')"
        />
      </template>
      <template #actions>
        <div class="flex items-center gap-2 ml-auto">
          <BulkLabelActions
            type="contact"
            :is-loading="isLoading"
            :disabled="!selectedCount"
            @assign="handleAssignLabels"
          />
          <BulkLabelActions
            type="contact"
            action="remove"
            :is-loading="isLoading"
            :disabled="!selectedCount"
            @remove="handleRemoveLabels"
          />
          <Button
            v-if="contactType !== 'customer'"
            sm
            ghost
            slate
            icon="i-lucide-badge-check"
            :label="t('CONTACTS_BULK_ACTIONS.MARK_AS_CUSTOMER')"
            :disabled="!selectedCount || isLoading"
            class="!px-2"
            @click="emit('changeContactType', 'customer')"
          />
          <Button
            v-if="contactType !== 'lead'"
            sm
            ghost
            slate
            icon="i-lucide-user-round"
            :label="t('CONTACTS_BULK_ACTIONS.MARK_AS_LEAD')"
            :disabled="!selectedCount || isLoading"
            class="!px-2"
            @click="emit('changeContactType', 'lead')"
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
  </div>
</template>
