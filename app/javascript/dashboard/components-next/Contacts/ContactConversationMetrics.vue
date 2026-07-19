<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const metrics = computed(() => {
  const contact = props.selectedContact || {};
  const total = Number(contact.conversationsCount ?? 0);
  const open = Number(contact.openConversationsCount ?? 0);
  const resolved = Number(contact.resolvedConversationsCount ?? 0);
  const other = Math.max(total - open - resolved, 0);

  return [
    {
      key: 'total',
      label: t('CONTACTS_LAYOUT.METRICS.TOTAL'),
      value: total.toLocaleString(),
      hint: t('CONTACTS_LAYOUT.METRICS.TOTAL_HINT'),
      tone: 'text-n-slate-12 bg-n-alpha-2',
    },
    {
      key: 'open',
      label: t('CONTACTS_LAYOUT.METRICS.OPEN'),
      value: open.toLocaleString(),
      hint: t('CONTACTS_LAYOUT.METRICS.OPEN_HINT'),
      tone: 'text-n-amber-11 bg-n-amber-3/40',
    },
    {
      key: 'resolved',
      label: t('CONTACTS_LAYOUT.METRICS.RESOLVED'),
      value: resolved.toLocaleString(),
      hint: t('CONTACTS_LAYOUT.METRICS.RESOLVED_HINT'),
      tone: 'text-n-teal-11 bg-n-teal-3/40',
    },
    {
      key: 'other',
      label: t('CONTACTS_LAYOUT.METRICS.OTHER'),
      value: other.toLocaleString(),
      hint: t('CONTACTS_LAYOUT.METRICS.OTHER_HINT'),
      tone: 'text-n-slate-11 bg-n-slate-3/40',
    },
  ];
});
</script>

<template>
  <section class="flex flex-col gap-2">
    <h4 class="text-sm font-medium text-n-slate-12 px-1">
      {{ t('CONTACTS_LAYOUT.METRICS.TITLE') }}
    </h4>
    <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <div
        v-for="metric in metrics"
        :key="metric.key"
        class="rounded-xl border border-n-weak p-3 min-w-0"
        :class="metric.tone"
      >
        <p class="text-xs font-medium truncate opacity-80">{{ metric.label }}</p>
        <p class="mt-1 text-2xl font-semibold tabular-nums tracking-tight">
          {{ metric.value }}
        </p>
        <p class="mt-1 text-[11px] leading-snug opacity-70 line-clamp-2">
          {{ metric.hint }}
        </p>
      </div>
    </div>
  </section>
</template>
