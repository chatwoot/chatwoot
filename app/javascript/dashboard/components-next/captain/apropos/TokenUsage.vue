<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({ events: { type: Array, default: () => [] } });
const { t, locale } = useI18n();
const usage = computed(() =>
  props.events.filter(event => event.kind === 'usage').map(event => event.data)
);
const totals = computed(() => {
  const input = usage.value.reduce(
    (sum, call) => sum + (call.input_tokens ?? 0),
    0
  );
  const output = usage.value.reduce(
    (sum, call) => sum + (call.output_tokens ?? 0),
    0
  );
  return [
    { label: t('CAPTAIN_ASK.TOKENS.INPUT'), value: input },
    { label: t('CAPTAIN_ASK.TOKENS.OUTPUT'), value: output },
    { label: t('CAPTAIN_ASK.TOKENS.TOTAL'), value: input + output },
  ];
});
const incomplete = computed(() =>
  usage.value.some(
    call => call.input_tokens == null || call.output_tokens == null
  )
);
const format = value => new Intl.NumberFormat(locale.value).format(value);
const description = computed(() => {
  if (!usage.value.length) return t('CAPTAIN_ASK.TOKENS.UNAVAILABLE');
  if (incomplete.value) return t('CAPTAIN_ASK.TOKENS.PARTIAL');
  return t('CAPTAIN_ASK.TOKENS.DESCRIPTION');
});
</script>

<template>
  <section class="px-5 py-4 border-b border-n-weak">
    <h3 class="m-0 mb-3 text-sm font-medium text-n-slate-12">
      {{ t('CAPTAIN_ASK.TOKENS.TITLE') }}
    </h3>
    <dl v-if="usage.length" class="grid grid-cols-3 gap-3 m-0">
      <div v-for="{ value, label } in totals" :key="label">
        <dt class="text-xs text-n-slate-10">
          {{ label }}
        </dt>
        <dd class="m-0 mt-1 text-sm font-medium tabular-nums text-n-slate-12">
          {{ format(value) }}
        </dd>
      </div>
    </dl>
    <p class="m-0 text-xs text-n-slate-10" :class="{ 'mt-3': usage.length }">
      {{ description }}
    </p>
  </section>
</template>
