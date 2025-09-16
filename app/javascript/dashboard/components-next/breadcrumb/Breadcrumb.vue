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

const onClick = (item, index) => {
  emit('click', item, index);
};
</script>

<template>
  <nav
    :aria-label="t('BREADCRUMB.ARIA_LABEL')"
    class="flex items-center h-8 min-w-0"
  >
    <ol class="flex items-center mb-0 min-w-0">
      <li
        v-for="(item, index) in items"
        :key="index"
        class="flex items-center"
        :class="{ 'min-w-0 flex-1': index === items.length - 1 }"
      >
        <Icon
          v-if="index > 0"
          icon="i-lucide-chevron-right"
          class="flex-shrink-0 mx-2 size-4 text-n-slate-11 dark:text-n-slate-11"
        />

        <!-- Render as button for all except the last item -->
        <button
          v-if="index !== items.length - 1"
          class="inline-flex items-center justify-center min-w-0 gap-2 p-0 text-sm font-medium transition-all duration-200 ease-in-out border-0 rounded-lg text-n-slate-11 hover:text-n-slate-12 outline-transparent max-w-56"
          @click="onClick(item, index)"
        >
          <span class="min-w-0 truncate">{{ item.label }}</span>
        </button>

        <!-- The last breadcrumb item is plain text -->
        <span v-else class="text-sm truncate text-n-slate-12 min-w-0 block">
          {{ item.emoji ? item.emoji : '' }} {{ item.label }}
        </span>
      </li>
    </ol>
  </nav>
</template>
