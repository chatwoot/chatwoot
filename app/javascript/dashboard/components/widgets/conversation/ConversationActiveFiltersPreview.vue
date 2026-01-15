<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useElementSize } from '@vueuse/core';

import ActiveFilterPreview from 'dashboard/components-next/filter/ActiveFilterPreview.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activeFolder: { type: Object, default: null },
  hasActiveFolders: { type: Boolean, default: false },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits([
  'clearFilters',
  'saveFolder',
  'deleteFolder',
  'openFilter',
]);

const { t } = useI18n();

const appliedFilters = useMapGetter('getAppliedConversationFiltersV2');

const activeFolderQuery = computed(() => {
  const query = props.activeFolder?.query?.payload;
  if (!Array.isArray(query)) return [];

  const newFilters = query.map(filter => {
    const transformed = useCamelCase(filter);
    return {
      attributeKey: transformed.attributeKey,
      attributeModel: transformed.attributeModel,
      customAttributeType: transformed.customAttributeType,
      filterOperator: transformed.filterOperator,
      queryOperator: transformed.queryOperator ?? 'and',
      values: transformed.values,
    };
  });

  return newFilters;
});

const activeFilterQueryData = computed(() => {
  return props.hasActiveFolders
    ? activeFolderQuery.value
    : appliedFilters.value;
});

const showPreview = computed(() => {
  return activeFilterQueryData.value.length > 0;
});

const containerRef = ref(null);
const { width: containerWidth } = useElementSize(containerRef);

const maxVisibleFilters = computed(() => {
  const totalFilters = activeFilterQueryData.value.length;
  const width = containerWidth.value;

  if (!width || totalFilters === 0) return 0;

  const chipWidth = 200; // Estimated avg width + gap
  const buttonSpace = 400; // Reserved space for "Edit/Delete/More" buttons

  // Calculate available space across 2 lines
  const totalAvailablePixels = Math.max(0, width * 2 - buttonSpace);
  const maxCapacity = Math.floor(totalAvailablePixels / chipWidth);
  // Return at least 1, but no more than actual total
  return Math.max(1, Math.min(maxCapacity, totalFilters));
});
</script>

<template>
  <div
    v-if="showPreview"
    ref="containerRef"
    class="flex items-center justify-between gap-2 mx-2 px-2 pb-2 pt-0.5 border-b-[1.2px] border-dashed border-n-strong mt-px"
  >
    <ActiveFilterPreview
      :applied-filters="activeFilterQueryData"
      :max-visible-filters="maxVisibleFilters"
      :more-filters-label="
        t('FILTER.ACTIVE_FILTERS.MORE_FILTERS', {
          count: activeFilterQueryData.length - maxVisibleFilters,
        })
      "
      :clear-button-label="t('FILTER.ACTIVE_FILTERS.CLEAR_FILTERS')"
      :show-clear-button="!hasActiveFolders"
      class="flex-1 min-w-0"
      @open-filter="emit('openFilter')"
      @clear-filters="emit('clearFilters')"
    >
      <template #actions>
        <template v-if="hasActiveFolders">
          <div class="w-px h-3 bg-n-weak rounded-lg" />
          <Button
            :label="t('FILTER.ACTIVE_FILTERS.EDIT_BUTTON')"
            link
            class="hover:!no-underline !text-n-blue-11 !px-0.5"
            xs
            @click="emit('openFilter')"
          />
          <div class="w-px h-3 bg-n-weak rounded-lg" />
          <div class="inline-flex items-center">
            <Button
              :label="t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
              link
              ruby
              class="hover:!no-underline !no-underline !px-0.5"
              xs
              @click="emit('deleteFolder')"
            />
            <!-- Teleport target for Delete modal -->
            <div
              id="deleteFilterTeleportTarget"
              class="absolute z-50 mt-2"
              :class="{ 'ltr:right-0 rtl:left-0': isOnExpandedLayout }"
            />
          </div>
        </template>
        <div
          v-if="appliedFilters.length > 0"
          class="w-px h-3 bg-n-weak rounded-lg"
        />
        <div
          v-if="appliedFilters.length > 0"
          class="relative inline-flex items-center"
        >
          <Button
            :label="t('FILTER.CUSTOM_VIEWS.SAVE_VIEW')"
            link
            class="hover:!no-underline !text-n-blue-11 !px-0.5"
            xs
            @click="emit('saveFolder')"
          />
          <!-- Teleport target for Save modal -->
          <div
            id="saveFilterTeleportTarget"
            class="absolute z-50 top-6"
            :class="{ 'ltr:left-0 rtl:right-0': isOnExpandedLayout }"
          />
        </div>
      </template>
    </ActiveFilterPreview>
  </div>
  <template v-else />
</template>
