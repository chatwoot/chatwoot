<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContactSortMenu from './components/ContactSortMenu.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';

defineProps({
  showSearch: {
    type: Boolean,
    default: true,
  },
  searchValue: {
    type: String,
    default: '',
  },
  headerTitle: {
    type: String,
    required: true,
  },
  //   buttonLabel: {
  //     type: String,
  //     default: '',
  //   },
  activeSort: {
    type: String,
    default: 'last_activity_at',
  },
  activeOrdering: {
    type: String,
    default: '',
  },
  isSegmentsView: {
    type: Boolean,
    default: false,
  },
  hasActiveFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'search',
  'filter',
  'update:sort',
  //   'message',
  'add',
  'import',
  'export',
  'createSegment',
  'deleteSegment',
]);
</script>

<template>
  <header class="sticky top-0 z-10 px-6 xl:px-0">
    <div
      class="flex items-center justify-between w-full h-20 gap-2 mx-auto max-w-[960px]"
    >
      <span class="text-xl font-medium truncate text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center flex-shrink-0 gap-4">
        <div v-if="showSearch" class="flex items-center gap-2">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            @input="emit('search', $event.target.value)"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
        </div>
        <div class="flex items-center gap-2">
          <div class="relative">
            <Button
              id="toggleContactsFilterButton"
              :icon="
                isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
              "
              color="slate"
              size="sm"
              class="relative"
              variant="ghost"
              @click="emit('filter')"
            >
              <div
                v-if="hasActiveFilters && !isSegmentsView"
                class="absolute top-0 right-0 w-2 h-2 rounded-full bg-n-brand"
              />
            </Button>
            <slot name="filter" />
          </div>
          <Button
            v-if="hasActiveFilters && !isSegmentsView"
            icon="i-lucide-save"
            color="slate"
            size="sm"
            class="relative"
            variant="ghost"
            @click="emit('createSegment')"
          />
          <Button
            v-if="isSegmentsView"
            icon="i-lucide-trash"
            color="slate"
            size="sm"
            class="relative"
            variant="ghost"
            @click="emit('deleteSegment')"
          />
          <ContactSortMenu
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />
          <ContactMoreActions
            @add="emit('add')"
            @import="emit('import')"
            @export="emit('export')"
          />
        </div>
        <!-- TODO: Add this when we enabling message feature -->
        <!-- <div class="w-px h-4 bg-n-strong" /> -->
        <!-- <Button :label="buttonLabel" size="sm" @click="emit('message')" /> -->
      </div>
    </div>
  </header>
</template>
