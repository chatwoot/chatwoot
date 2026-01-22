<script setup>
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContactSortMenu from './components/ContactSortMenu.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import DisplayPropertiesMenu from './components/DisplayPropertiesMenu.vue';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  buttonLabel: { type: String, default: '' },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'update:sort',
  'add',
  'import',
  'export',
  'createSegment',
  'deleteSegment',
]);

const [showDisplayProperties, toggleDisplayProperties] = useToggle(false);

const closeDisplayProperties = () => {
  if (showDisplayProperties.value) {
    toggleDisplayProperties(false);
  }
};
</script>

<template>
  <header class="sticky top-0 z-10">
    <div
      class="flex items-start sm:items-center justify-between w-full py-4 px-6 gap-2 mx-auto after:absolute after:inset-x-0 after:-bottom-4 after:bg-gradient-to-b after:from-n-surface-1 after:from-10% after:dark:from-0% after:to-transparent after:h-4 after:pointer-events-none"
    >
      <span class="text-heading-1 truncate text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-3">
        <div v-if="showSearch" class="flex items-center gap-2 w-full">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
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
        <div class="flex items-center flex-shrink-0 gap-2">
          <div class="w-px h-3 rounded-lg bg-n-strong" />
          <div v-on-click-outside="closeDisplayProperties" class="relative">
            <Button
              icon="i-lucide-settings-2"
              color="slate"
              :label="$t('CONTACTS_LAYOUT.HEADER.DISPLAY_PROPERTIES')"
              size="sm"
              :variant="!showDisplayProperties ? 'ghost' : 'faded'"
              @click="toggleDisplayProperties()"
            />
            <DisplayPropertiesMenu
              v-if="showDisplayProperties"
              class="absolute top-full mt-1 max-md:ltr:left-0 max-md:rtl:right-0 md:ltr:right-0 md:rtl:left-0"
            />
          </div>
          <div class="w-px h-3 rounded-lg bg-n-strong mx-1" />
          <div class="flex items-center gap-2">
            <div v-if="!isLabelView && !isActiveView" class="relative">
              <Button
                id="toggleContactsFilterButton"
                :icon="
                  isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
                "
                color="slate"
                size="sm"
                class="relative w-8"
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
              v-if="
                hasActiveFilters &&
                !isSegmentsView &&
                !isLabelView &&
                !isActiveView
              "
              icon="i-lucide-save"
              color="slate"
              size="sm"
              variant="ghost"
              @click="emit('createSegment')"
            />
            <Button
              v-if="isSegmentsView && !isLabelView && !isActiveView"
              icon="i-lucide-trash"
              color="slate"
              size="sm"
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
          <div
            class="w-px h-3 rounded-lg bg-n-strong ltr:ml-1 rtl:mr-2 ltr:mr-1 rtl:ml-2"
          />
          <ComposeConversation>
            <template #trigger="{ toggle }">
              <Button :label="buttonLabel" size="sm" @click="toggle" />
            </template>
          </ComposeConversation>
        </div>
      </div>
    </div>
  </header>
</template>
