<script setup>
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MonitorTemplateCard from './MonitorTemplateCard.vue';

defineProps({ template: { type: Object, required: true } });
const emit = defineEmits(['create', 'browse']);

const { t } = useI18n();
const { isAdmin } = useAdmin();
</script>

<template>
  <section class="flex flex-col items-center gap-5 py-12 text-center">
    <span
      class="flex size-12 items-center justify-center rounded-xl bg-n-alpha-2 text-n-brand"
    >
      <Icon icon="i-lucide-chart-no-axes-combined" class="size-6" />
    </span>
    <div class="flex flex-col items-center gap-2">
      <h2 class="m-0 text-heading-2 text-n-slate-12">
        {{ t('MONITORS.EMPTY_TITLE') }}
      </h2>
      <p class="m-0 max-w-xl text-body-main text-n-slate-11">
        {{ t('MONITORS.EMPTY_DESCRIPTION') }}
      </p>
    </div>
    <MonitorTemplateCard
      :template="template"
      :can-create="isAdmin"
      class="w-full max-w-xl text-start"
      @use="emit('create', template)"
    />
    <button
      type="button"
      class="min-h-11 rounded-md text-sm font-medium text-n-brand hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
      @click="emit('browse')"
    >
      {{ t('MONITORS.TEMPLATES.VIEW_ALL') }}
      <Icon
        icon="i-lucide-arrow-right"
        class="inline size-4 rtl:rotate-180"
        aria-hidden="true"
      />
    </button>
    <p v-if="!isAdmin" class="m-0 text-sm text-n-slate-11">
      {{ t('MONITORS.ADMIN_HELP') }}
    </p>
  </section>
</template>
