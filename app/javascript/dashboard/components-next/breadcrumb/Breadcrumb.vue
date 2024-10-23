<script setup>
import { defineProps } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

defineProps({
  items: {
    type: Array,
    required: true,
    validator: value => {
      return value.every(
        item =>
          typeof item.label === 'string' &&
          (item.link === undefined || typeof item.link === 'string') &&
          (item.count === undefined || typeof item.count === 'number')
      );
    },
  },
});

const emit = defineEmits(['click']);

const { t } = useI18n();

const onClick = event => {
  emit('click', event);
};
</script>

<template>
  <nav :aria-label="t('BREADCRUMB.ARIA_LABEL')" class="flex items-center h-8">
    <ol class="flex items-center mb-0">
      <li v-for="(item, index) in items" :key="index" class="flex items-center">
        <Button
          v-if="index === 0"
          :label="item.label"
          variant="link"
          text-variant="info"
          class="!p-0 text-sm !font-normal hover:!no-underline max-w-56 !text-slate-300 dark:!text-slate-500 hover:!text-slate-700 dark:hover:!text-slate-100"
          size="sm"
          @click="onClick"
        />
        <template v-else>
          <FluentIcon
            icon="chevron-lucide-right"
            size="18"
            icon-lib="lucide"
            class="flex-shrink-0 mx-2 text-slate-300 dark:text-slate-500"
          />
          <span
            class="text-sm truncate text-slate-900 dark:text-slate-50 max-w-56"
          >
            {{ item.emoji ? item.emoji : '' }} {{ item.label }}
          </span>
        </template>
      </li>
    </ol>
  </nav>
</template>
