<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  value: { type: [Object, Array, String, Number, Boolean], default: null },
});
const PAGE_SIZE = 5;
const visibleCount = ref(PAGE_SIZE);
const { t } = useI18n();
const isList = computed(() => Array.isArray(props.value));
const isObject = computed(
  () => props.value !== null && typeof props.value === 'object' && !isList.value
);
const label = key => key.replace(/[_-]/g, ' ');
const scalar = computed(() => {
  if (props.value === null) return t('CAPTAIN_ASK.TRACE.NOT_SET');
  if (props.value === true) return t('CAPTAIN_ASK.TRACE.YES');
  if (props.value === false) return t('CAPTAIN_ASK.TRACE.NO');
  return props.value === ''
    ? t('CAPTAIN_ASK.TRACE.EMPTY')
    : String(props.value);
});
</script>

<template>
  <div v-if="isList" class="min-w-0 space-y-2">
    <p class="m-0 text-xs text-n-slate-10">
      {{ t('CAPTAIN_ASK.TRACE.ITEMS', { count: value.length }) }}
    </p>
    <div
      v-for="(item, index) in value.slice(0, visibleCount)"
      :key="index"
      class="flex gap-3 py-2 border-t border-n-weak"
    >
      <span class="text-xs tabular-nums text-n-slate-9 shrink-0">{{
        index + 1
      }}</span>
      <ActivityValue :value="item" class="flex-1 min-w-0" />
    </div>
    <Button
      v-if="value.length > visibleCount"
      xs
      ghost
      slate
      :label="
        t('CAPTAIN_ASK.TRACE.SHOW_MORE', {
          count: Math.min(PAGE_SIZE, value.length - visibleCount),
        })
      "
      @click="visibleCount += PAGE_SIZE"
    />
  </div>
  <dl v-else-if="isObject" class="m-0 min-w-0 space-y-2">
    <div v-for="(item, key) in value" :key="key" class="min-w-0">
      <dt class="text-xs font-medium text-n-slate-10 capitalize mb-1">
        {{ label(key) }}
      </dt>
      <dd class="m-0 ps-3 border-s border-n-weak min-w-0">
        <ActivityValue :value="item" />
      </dd>
    </div>
    <span v-if="!Object.keys(value).length" class="text-xs text-n-slate-10">{{
      t('CAPTAIN_ASK.TRACE.EMPTY')
    }}</span>
  </dl>
  <p v-else class="m-0 text-sm text-n-slate-12 whitespace-pre-wrap break-words">
    {{ scalar }}
  </p>
</template>
