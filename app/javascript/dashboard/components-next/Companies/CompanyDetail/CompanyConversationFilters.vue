<script setup>
import { computed, onMounted, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useStore } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import { useConversationFilterContext } from 'dashboard/components-next/filter/provider';

// ConversationFilter conditions; each simple filter maps to one `equal_to` condition.
const filters = defineModel({ type: Array, default: () => [] });

const SIMPLE_FILTER_KEYS = [
  'status',
  'assignee_id',
  'inbox_id',
  'team_id',
  'priority',
  'labels',
];

const { t } = useI18n();
const store = useStore();
// Same attributes, labels and options as the conversation list's filter.
const { attributeFilterTypes } = useConversationFilterContext();
const [showFilters, toggleFilters] = useToggle();
const toggleButton = useTemplateRef('toggleButton');

// The toggle button handles its own clicks; ignore it so opening doesn't immediately close.
const closeOnClickOutside = [
  () => toggleFilters(false),
  { ignore: [toggleButton] },
];

// Assignee options need agents, which the dashboard doesn't load globally.
onMounted(() => store.dispatch('agents/get'));

const simpleFilters = computed(() =>
  SIMPLE_FILTER_KEYS.map(key =>
    attributeFilterTypes.value.find(type => type.attributeKey === key)
  )
    .filter(Boolean)
    .map(type => ({
      key: type.attributeKey,
      label: type.label,
      options: type.options.filter(option => option.id !== 'all'),
    }))
);

const activeCount = computed(() => filters.value.length);

const selectedOption = key =>
  filters.value.find(filter => filter.attributeKey === key)?.values?.[0] ||
  null;

const setFilter = (key, option) => {
  const others = filters.value.filter(filter => filter.attributeKey !== key);
  filters.value = option
    ? [
        ...others,
        {
          attributeKey: key,
          filterOperator: 'equal_to',
          values: [option],
          queryOperator: 'and',
        },
      ]
    : others;
};

const clearFilters = () => {
  filters.value = [];
};
</script>

<template>
  <div class="relative">
    <Button
      ref="toggleButton"
      :label="
        activeCount
          ? t('COMPANIES.DETAIL.CONVERSATION_FILTERS.BUTTON_WITH_COUNT', {
              count: activeCount,
            })
          : t('COMPANIES.DETAIL.CONVERSATION_FILTERS.BUTTON')
      "
      icon="i-lucide-list-filter"
      slate
      :faded="!activeCount"
      sm
      @click="toggleFilters()"
    />
    <div
      v-if="showFilters"
      v-on-click-outside="closeOnClickOutside"
      class="absolute z-40 flex flex-col gap-4 p-4 mt-1 border bg-n-alpha-3 backdrop-blur-[100px] border-n-weak w-80 rounded-xl top-full ltr:right-0 rtl:left-0"
    >
      <div
        v-for="filter in simpleFilters"
        :key="filter.key"
        class="flex items-center justify-between gap-3"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{ filter.label }}
        </span>
        <SingleSelect
          :model-value="selectedOption(filter.key)"
          :options="filter.options"
          :placeholder="t('COMPANIES.DETAIL.CONVERSATION_FILTERS.ANY')"
          placeholder-icon="i-lucide-chevron-down"
          placeholder-trailing-icon
          dropdown-max-height="max-h-64"
          @update:model-value="option => setFilter(filter.key, option)"
        />
      </div>
      <Button
        v-if="activeCount"
        :label="t('FILTER.CLEAR_BUTTON_LABEL')"
        variant="link"
        color="slate"
        size="xs"
        class="self-end"
        @click="clearFilters"
      />
    </div>
  </div>
</template>
