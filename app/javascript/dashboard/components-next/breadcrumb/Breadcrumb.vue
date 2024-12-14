<script setup>
import { defineProps } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  items: {
    type: Array,
    required: true,
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
        <button
          v-if="index === 0"
          class="inline-flex items-center justify-center min-w-0 gap-2 p-0 text-sm font-medium transition-all duration-200 ease-in-out border-0 rounded-lg text-n-slate-11 hover:text-n-slate-12 outline-transparent max-w-56"
          @click="onClick"
        >
          <span class="min-w-0 truncate">{{ item.label }}</span>
        </button>
        <template v-else>
          <Icon
            icon="i-lucide-chevron-right"
            class="flex-shrink-0 mx-2 size-4 text-n-slate-11 dark:text-n-slate-11"
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
