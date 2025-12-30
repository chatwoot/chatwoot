<script setup>
import { computed } from 'vue';
import ConversationBasicFilter from './widgets/conversation/ConversationBasicFilter.vue';

const props = defineProps({
  pageTitle: {
    type: String,
    required: true,
  },
  hasAppliedFilters: {
    type: Boolean,
    required: true,
  },
  hasActiveFolders: {
    type: Boolean,
    required: true,
  },
  activeStatus: {
    type: String,
    required: true,
  },
  conversationCount: {
    type: Number,
    default: 0,
  },
});

const emits = defineEmits([
  'add-folders',
  'delete-folders',
  'reset-filters',
  'basic-filter-change',
  'filters-modal',
]);

const onBasicFilterChange = (value, type) => {
  emits('basic-filter-change', value, type);
};

const hasAppliedFiltersOrActiveFolders = computed(() => {
  return props.hasAppliedFilters || props.hasActiveFolders;
});
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-0"
    :class="{
      'pb-3 border-b border-slate-75 dark:border-slate-700':
        hasAppliedFiltersOrActiveFolders,
    }"
  >
    <div class="flex max-w-[85%] justify-center items-center">
      <h1
        class="text-xl font-medium break-words truncate text-black-900 dark:text-slate-100"
        :title="pageTitle"
      >
        {{ pageTitle }}
      </h1>
      <div
        v-if="hasAppliedFiltersOrActiveFolders && conversationCount > 0"
        class="bg-slate-50 dark:bg-slate-800 rounded-md text-slate-600 dark:text-slate-100 h-5 flex items-center justify-center text-xxs font-semibold my-0 mx-1 px-1 py-0 min-w-[20px]"
      >
        <span>
          {{ conversationCount }}
        </span>
      </div>
      <span
        v-if="!hasAppliedFiltersOrActiveFolders"
        class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
      >
        {{ $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus}.TEXT`) }}
      </span>
    </div>
    <div class="flex items-center gap-1">
      <div v-if="hasAppliedFilters && !hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="save"
          @click="emits('add-folders')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="dismiss-circle"
          @click="emits('reset-filters')"
        />
      </div>
      <div v-if="hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="edit"
          @click="emits('filters-modal')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="delete"
          @click="emits('delete-folders')"
        />
      </div>
      <woot-button
        v-else
        v-tooltip.right="$t('FILTER.TOOLTIP_LABEL')"
        variant="smooth"
        color-scheme="secondary"
        icon="filter"
        size="tiny"
        @click="emits('filters-modal')"
      />
      <conversation-basic-filter
        v-if="!hasAppliedFiltersOrActiveFolders"
        @changeFilter="onBasicFilterChange"
      />
    </div>
  </div>
</template>
