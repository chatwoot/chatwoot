<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useArticleListSort } from 'dashboard/composables/useArticleListSort';

import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const { t } = useI18n();
const { appliesHere, sortField, sortOrder, setSort } = useArticleListSort();

const isMenuOpen = ref(false);

const fieldOptions = computed(() => [
  {
    label: t(
      'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.FIELDS.UPDATED_AT'
    ),
    value: 'updated_at',
  },
  {
    label: t(
      'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.FIELDS.CREATED_AT'
    ),
    value: 'created_at',
  },
  {
    label: t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.FIELDS.TITLE'),
    value: 'title',
  },
  {
    label: t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.FIELDS.VIEWS'),
    value: 'views',
  },
]);

const orderOptions = computed(() => [
  {
    label: t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.ORDERS.ASCENDING'),
    value: '',
  },
  {
    label: t(
      'HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.ORDERS.DESCENDING'
    ),
    value: '-',
  },
]);

const labelOf = (options, value) =>
  options.find(option => option.value === value)?.label;
</script>

<template>
  <div v-if="appliesHere" class="relative ms-auto">
    <Button
      v-tooltip.top="t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.BUTTON')"
      icon="i-lucide-arrow-down-up"
      color="slate"
      size="sm"
      variant="ghost"
      :aria-label="t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.BUTTON')"
      :class="isMenuOpen ? 'bg-n-alpha-2' : ''"
      @click="isMenuOpen = !isMenuOpen"
    />
    <div
      v-if="isMenuOpen"
      v-on-clickaway="() => (isMenuOpen = false)"
      class="absolute top-full mt-1 ltr:right-0 rtl:left-0 flex flex-col gap-4 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-72 max-w-[calc(100vw-5rem)] rounded-xl p-4 z-50"
    >
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.SORT_BY') }}
        </span>
        <SelectMenu
          :model-value="sortField"
          :options="fieldOptions"
          sub-menu-position="bottom"
          :label="labelOf(fieldOptions, sortField)"
          @update:model-value="field => setSort({ field, order: sortOrder })"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.SORT.ORDER') }}
        </span>
        <SelectMenu
          :model-value="sortOrder"
          :options="orderOptions"
          sub-menu-position="bottom"
          :label="labelOf(orderOptions, sortOrder)"
          @update:model-value="order => setSort({ field: sortField, order })"
        />
      </div>
    </div>
  </div>
</template>
