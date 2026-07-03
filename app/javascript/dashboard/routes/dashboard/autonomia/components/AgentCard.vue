<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select', 'delete']);

const { t } = useI18n();

// Human-facing summary only — the generated instruction/scaffold is IP and is
// never read here (the serializer hides it in guided mode anyway). `human_card`
// is a plain string on the agent payload (builder stores it via `.to_s`).
const summary = computed(() => props.agent?.human_card || '');

const channelsCount = computed(() => props.agent?.channels_count ?? 0);

// Performance metrics arrive in a later phase; show an em dash until then.
const metricPlaceholder = '—';

// Status drives a small colored pill. Unknown statuses fall back to "draft".
const STATUS_STYLES = {
  active: 'bg-n-teal-3 text-n-teal-11',
  paused: 'bg-n-amber-3 text-n-amber-11',
  draft: 'bg-n-slate-3 text-n-slate-11',
};

// A tiny leading dot inside the pill, tinted to match the status.
const STATUS_DOT = {
  active: 'bg-n-teal-9',
  paused: 'bg-n-amber-9',
  draft: 'bg-n-slate-9',
};

const status = computed(() => props.agent?.status || 'draft');

const statusClass = computed(
  () => STATUS_STYLES[status.value] || STATUS_STYLES.draft
);

const statusDotClass = computed(
  () => STATUS_DOT[status.value] || STATUS_DOT.draft
);

const statusLabel = computed(() => {
  if (status.value === 'active') return t('AGENTS.HUB.STATUS.ACTIVE');
  if (status.value === 'paused') return t('AGENTS.HUB.STATUS.PAUSED');
  return t('AGENTS.HUB.STATUS.DRAFT');
});
</script>

<template>
  <article
    class="flex flex-col w-full gap-3 p-4 text-left transition-all duration-150 border shadow-sm rounded-xl border-n-weak bg-n-solid-1 hover:border-n-slate-6 hover:shadow-md hover:-translate-y-0.5"
  >
    <div class="flex items-start gap-3">
      <Avatar
        :name="agent.name"
        :src="agent.avatar_url"
        :size="40"
        rounded-full
      />
      <button
        type="button"
        class="flex flex-col min-w-0 gap-1.5 text-left outline-1 outline-transparent rounded-md focus-visible:outline-n-brand"
        @click="emit('select', agent)"
      >
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ agent.name }}
        </span>
        <span class="flex flex-wrap items-center gap-1.5">
          <span
            class="inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full w-fit"
            :class="statusClass"
          >
            <span class="rounded-full size-1.5" :class="statusDotClass" />
            {{ statusLabel }}
          </span>
          <!-- Interno x externo eram indistinguíveis no hub — selo do copiloto. -->
          <span
            v-if="agent.actuation === 'internal'"
            class="inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-full w-fit bg-n-iris-3 text-n-iris-11"
          >
            <span class="i-lucide-headset size-3" />
            {{ t('AGENTS.HUB.INTERNAL_BADGE') }}
          </span>
        </span>
      </button>
    </div>

    <button
      type="button"
      class="m-0 text-sm text-left outline-1 outline-transparent rounded-md line-clamp-2 text-n-slate-11 focus-visible:outline-n-brand"
      @click="emit('select', agent)"
    >
      {{ summary }}
    </button>

    <div
      class="flex items-center gap-4 pt-3 mt-auto text-xs border-t text-n-slate-11 border-n-weak"
    >
      <span class="flex items-center gap-1.5">
        <span class="i-lucide-radio-tower size-3.5" />
        {{ t('AGENTS.HUB.CHANNELS_COUNT', { count: channelsCount }) }}
      </span>
      <span class="flex items-center gap-1.5">
        <span class="i-lucide-bar-chart-3 size-3.5" />
        {{ metricPlaceholder }}
      </span>
    </div>

    <div class="flex flex-wrap items-center justify-end gap-2 pt-1">
      <!-- Rascunho sem ação de publicar era beco sem saída — leva pra aba
           de publicação (AgentsHubPage já roteia draft -> tab publish). -->
      <NextButton
        v-if="status === 'draft'"
        ghost
        blue
        xs
        icon="i-lucide-rocket"
        :label="t('AGENTS.HUB.PUBLISH')"
        @click="emit('select', agent)"
      />
      <NextButton
        ghost
        ruby
        xs
        icon="i-lucide-trash-2"
        :label="t('AGENTS.HUB.DELETE')"
        @click="emit('delete', agent)"
      />
    </div>
  </article>
</template>
