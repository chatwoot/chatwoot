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
const tableColumns = computed(() => {
  if (!isList.value || !props.value.length) return [];

  const [firstRow] = props.value;
  if (!firstRow || typeof firstRow !== 'object' || Array.isArray(firstRow)) {
    return [];
  }

  const columns = Object.keys(firstRow);
  const hasMatchingRows = props.value.every(
    row =>
      row !== null &&
      typeof row === 'object' &&
      !Array.isArray(row) &&
      Object.keys(row).length === columns.length &&
      columns.every(
        key =>
          Object.prototype.hasOwnProperty.call(row, key) &&
          (row[key] === null ||
            ['string', 'number', 'boolean'].includes(typeof row[key]))
      )
  );

  return hasMatchingRows ? columns : [];
});
const label = key => key.replace(/[_-]/g, ' ');
const scalar = value => {
  if (value === null) return t('CAPTAIN_ASK.TRACE.NOT_SET');
  if (value === true) return t('CAPTAIN_ASK.TRACE.YES');
  if (value === false) return t('CAPTAIN_ASK.TRACE.NO');
  return value === '' ? t('CAPTAIN_ASK.TRACE.EMPTY') : String(value);
};
</script>

<template>
  <div v-if="isList" class="min-w-0 space-y-2">
    <p class="m-0 text-xs text-n-slate-10">
      {{ t('CAPTAIN_ASK.TRACE.ITEMS', { count: value.length }) }}
    </p>
    <div
      v-if="tableColumns.length"
      class="overflow-x-auto rounded-lg border border-n-weak"
      tabindex="0"
      role="region"
      :aria-label="t('CAPTAIN_ASK.TRACE.OUTPUT')"
    >
      <table class="w-full text-xs text-start">
        <thead class="bg-n-alpha-2">
          <tr>
            <th
              v-for="column in tableColumns"
              :key="column"
              scope="col"
              class="px-3 py-2 font-medium text-start text-n-slate-11 capitalize"
            >
              {{ label(column) }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(row, index) in value.slice(0, visibleCount)"
            :key="index"
            class="border-t border-n-weak"
          >
            <td
              v-for="column in tableColumns"
              :key="column"
              class="px-3 py-2 max-w-xs text-start text-n-slate-12 tabular-nums whitespace-pre-wrap break-words"
            >
              {{ scalar(row[column]) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <template v-else>
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
    </template>
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
    {{ scalar(value) }}
  </p>
</template>
