<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  faqImport: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const STATUS_CONFIG = {
  preparing: {
    icon: 'i-lucide-file-up',
    className: 'text-n-blue-11',
    iconBg: 'bg-n-blue-3',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.PREPARING.TITLE'),
    description: counts =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.PREPARING.DESCRIPTION', counts),
  },
  completed: {
    icon: 'i-lucide-circle-check',
    className: 'text-n-teal-11',
    iconBg: 'bg-n-teal-3',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED.TITLE'),
    description: counts =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED.DESCRIPTION', counts),
  },
  completed_with_errors: {
    icon: 'i-lucide-triangle-alert',
    className: 'text-n-amber-11',
    iconBg: 'bg-n-amber-3',
    title: () =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED_WITH_ERRORS.TITLE'),
    description: counts =>
      t(
        'CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED_WITH_ERRORS.DESCRIPTION',
        counts
      ),
  },
  failed: {
    icon: 'i-lucide-circle-alert',
    className: 'text-n-ruby-11',
    iconBg: 'bg-n-ruby-3',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.FAILED.TITLE'),
    description: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.FAILED.DESCRIPTION'),
  },
};

const status = computed(() => {
  const config = STATUS_CONFIG[props.faqImport.status];
  return {
    icon: config.icon,
    className: config.className,
    iconBg: config.iconBg,
    title: config.title(),
    description: config.description({
      created: props.faqImport.created_count || 0,
      overwritten: props.faqImport.overwritten_count || 0,
      skipped: props.faqImport.skipped_count || 0,
    }),
  };
});
</script>

<template>
  <section
    data-testid="faq-import-status"
    :data-status="faqImport.status"
    role="status"
    aria-live="polite"
    class="flex items-center gap-3 rounded-xl border border-n-weak bg-n-solid-1 px-4 py-3"
  >
    <span
      class="grid size-10 shrink-0 place-items-center rounded-full"
      :class="[status.iconBg, status.className]"
    >
      <Spinner v-if="faqImport.status === 'preparing'" :size="20" />
      <Icon v-else :icon="status.icon" class="size-5" />
    </span>
    <div class="min-w-0 flex-1">
      <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ status.title }}
        </span>
        <span
          class="truncate rounded-md bg-n-alpha-2 px-1.5 py-0.5 text-xs text-n-slate-11"
        >
          {{ faqImport.original_filename }}
        </span>
      </div>
      <p class="mb-0 mt-0.5 text-sm text-n-slate-11">
        {{ status.description }}
      </p>
    </div>
  </section>
</template>
