<script setup>
import { defineProps } from 'vue';
import { useI18n } from 'vue-i18n';
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
  countLabel: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
</script>

<template>
  <nav :aria-label="t('BREADCRUMB.ARIA_LABEL')" class="flex items-center h-8">
    <ol class="flex items-center mb-0">
      <li
        v-for="(item, index) in items"
        :key="index"
        class="flex items-center gap-3"
      >
        <template v-if="index === items.length - 1">
          <span class="text-sm text-slate-900 dark:text-slate-50">
            {{
              `${item.label}${item.count ? ` (${item.count} ${countLabel})` : ''}`
            }}
          </span>
        </template>
        <a
          v-else
          :href="item.link"
          class="text-sm transition-colors duration-200 text-slate-300 dark:text-slate-500 hover:text-slate-700 dark:hover:text-slate-100"
        >
          {{ item.label }}
        </a>
        <FluentIcon
          v-if="index < items.length - 1"
          icon="chevron-lucide-right"
          size="18"
          icon-lib="lucide"
          class="flex-shrink-0 text-slate-300 dark:text-slate-500 ltr:mr-3 rtl:mr-0 rtl:ml-3"
        />
      </li>
    </ol>
  </nav>
</template>
