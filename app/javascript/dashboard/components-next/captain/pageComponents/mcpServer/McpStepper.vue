<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  steps: { type: Array, required: true },
  current: { type: Number, required: true },
});

const { t } = useI18n();
</script>

<template>
  <ol class="flex items-center gap-2 p-0 m-0 list-none">
    <template v-for="(name, index) in steps" :key="name">
      <li class="flex items-center gap-2 shrink-0">
        <span
          class="flex items-center justify-center text-xs font-medium transition-colors rounded-full size-6 tabular-nums"
          :class="{
            'bg-n-brand text-white': index <= current,
            'outline outline-1 -outline-offset-1 outline-n-weak text-n-slate-10':
              index > current,
          }"
        >
          <i v-if="index < current" class="i-lucide-check size-3.5" />
          <template v-else>{{ index + 1 }}</template>
        </span>
        <span
          class="text-sm"
          :class="{
            'font-medium text-n-slate-12': index === current,
            'text-n-slate-11': index < current,
            'text-n-slate-10': index > current,
          }"
        >
          {{ t(`CAPTAIN.MCP_SERVERS.DIALOG.STEPS.${name}`) }}
        </span>
      </li>
      <li
        v-if="index < steps.length - 1"
        aria-hidden="true"
        class="flex-1 h-px min-w-4 transition-colors"
        :class="index < current ? 'bg-n-brand' : 'bg-n-weak'"
      />
    </template>
  </ol>
</template>
