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
});

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'basicFilterChange',
  'filtersModal',
]);

const onBasicFilterChange = (value, type) => {
  emit('basicFilterChange', value, type);
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
      <span
        v-if="!hasAppliedFiltersOrActiveFolders"
        class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
      >
        {{ $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus}.TEXT`) }}
      </span>
    </div>
    <div class="flex items-center gap-1">
      <template v-if="hasAppliedFilters && !hasActiveFolders">
        <div class="relative">
          <woot-button
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="secondary"
            icon="save"
            @click="emit('addFolders')"
          />
          <div id="saveFilterTeleportTarget" class="absolute mt-2 z-40" />
        </div>

        <woot-button
          v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="dismiss-circle"
          @click="emit('resetFilters')"
        />
      </template>
      <template v-if="hasActiveFolders">
        <div class="relative">
          <woot-button
            id="toggleConversationFilterButton"
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="secondary"
            icon="edit"
            @click="emit('filtersModal')"
          />
          <div
            id="conversationFilterTeleportTarget"
            class="absolute mt-2 z-40"
          />
        </div>
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="delete"
          @click="emit('deleteFolders')"
        />
      </template>
      <div v-else class="relative">
        <woot-button
          id="toggleConversationFilterButton"
          v-tooltip.right="$t('FILTER.TOOLTIP_LABEL')"
          variant="smooth"
          color-scheme="secondary"
          icon="filter"
          size="tiny"
          @click="emit('filtersModal')"
        />
        <div id="conversationFilterTeleportTarget" class="absolute mt-2 z-40" />
      </div>
      <ConversationBasicFilter
        v-if="!hasAppliedFiltersOrActiveFolders"
        @change-filter="onBasicFilterChange"
      />
    </div>
  </div>
</template>
