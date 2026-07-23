<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  knowledge: {
    type: Object,
    default: () => ({ approved: 0, pending: 0, documents: 0, coverage: 0 }),
  },
});

const { t } = useI18n();
const route = useRoute();

const approvedPct = computed(() => props.knowledge.coverage ?? 0);

const linkTo = routeName => ({
  name: routeName,
  params: {
    accountId: route.params.accountId,
    assistantId: route.params.assistantId,
  },
});

const stats = computed(() => [
  {
    key: 'approved',
    value: props.knowledge.approved,
    label: t('CAPTAIN.OVERVIEW.KNOWLEDGE.APPROVED'),
    to: linkTo('captain_assistants_responses_index'),
  },
  {
    key: 'pending',
    value: props.knowledge.pending,
    label: t('CAPTAIN.OVERVIEW.KNOWLEDGE.PENDING'),
    to: linkTo('captain_assistants_responses_pending'),
  },
  {
    key: 'documents',
    value: props.knowledge.documents,
    label: t('CAPTAIN.OVERVIEW.KNOWLEDGE.DOCUMENTS'),
    to: linkTo('captain_assistants_documents_index'),
  },
]);
</script>

<template>
  <div
    class="flex flex-col gap-4 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('CAPTAIN.OVERVIEW.KNOWLEDGE.TITLE') }}
      </span>
      <span class="text-sm tabular-nums text-n-slate-11">
        {{ $t('CAPTAIN.OVERVIEW.KNOWLEDGE.COVERAGE', { pct: approvedPct }) }}
      </span>
    </div>
    <div class="w-full h-2 overflow-hidden rounded-full bg-n-alpha-2">
      <div
        class="h-full rounded-full bg-n-brand"
        :style="{ width: `${approvedPct}%` }"
      />
    </div>
    <div class="grid grid-cols-3 gap-3">
      <RouterLink
        v-for="stat in stats"
        :key="stat.key"
        :to="stat.to"
        class="flex flex-col gap-1 group/stat"
      >
        <span class="text-xl font-semibold tabular-nums text-n-slate-12">
          {{ stat.value }}
        </span>
        <span
          class="inline-flex items-center gap-1 text-xs transition-colors text-n-slate-11 group-hover/stat:text-n-slate-12"
        >
          {{ stat.label }}
          <span
            class="transition-opacity opacity-0 i-lucide-arrow-up-right size-3 group-hover/stat:opacity-100"
          />
        </span>
      </RouterLink>
    </div>
  </div>
</template>
