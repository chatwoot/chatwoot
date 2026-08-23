<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const items = [
  {
    key: 'active',
    swatchClass: 'bg-n-teal-9',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_LEGEND.ACTIVE',
  },
  {
    key: 'waiting',
    swatchClass: 'bg-n-amber-9',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_LEGEND.WAITING',
  },
  {
    key: 'help',
    swatchClass: 'bg-n-ruby-9',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_LEGEND.HELP',
  },
  {
    key: 'closed',
    swatchClass: 'bg-n-slate-9',
    labelKey: 'CONVERSATION.PANEL_IA_STATE_LEGEND.INACTIVITY_CLOSED',
  },
];
</script>

<template>
  <div
    class="rounded-xl border border-n-slate-4 bg-n-slate-3 px-3 py-2 text-sm text-n-slate-11"
  >
    <p class="text-body-main font-medium text-n-slate-12">
      {{ t('CONVERSATION.PANEL_IA_STATE_LEGEND.TITLE') }}
    </p>
    <ul class="mt-2 flex flex-wrap gap-x-4 gap-y-1.5">
      <li
        v-for="item in items"
        :key="item.key"
        class="inline-flex items-center gap-2"
      >
        <span
          class="inline-block h-2.5 w-2.5 shrink-0 rounded-sm opacity-80"
          :class="item.swatchClass"
          aria-hidden="true"
        />
        <span>{{ t(item.labelKey) }}</span>
      </li>
    </ul>
    <p class="mt-2 text-xs text-n-slate-11">
      {{ t('CONVERSATION.PANEL_IA_STATE_LEGEND.HUMAN_NOTE') }}
    </p>
  </div>
</template>
