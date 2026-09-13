<script setup>
import { useI18n } from 'vue-i18n';

defineProps({ table: { type: Object, required: true } });
const { t } = useI18n();
const label = key => key.replace(/[_-]/g, ' ');
const cell = value => {
  if (value === null) return t('CAPTAIN_ASK.TRACE.NOT_SET');
  if (value === true) return t('CAPTAIN_ASK.TRACE.YES');
  if (value === false) return t('CAPTAIN_ASK.TRACE.NO');
  return value === '' ? t('CAPTAIN_ASK.TRACE.EMPTY') : String(value);
};
</script>

<template>
  <div
    class="ms-8 max-h-[28rem] overflow-auto rounded-xl border border-n-weak bg-n-solid-1"
    tabindex="0"
    role="region"
    :aria-label="t('CAPTAIN_ASK.TRACE.OUTPUT')"
  >
    <table class="w-full text-body-main text-start">
      <thead class="sticky top-0 bg-n-solid-2">
        <tr>
          <th
            v-for="column in table.columns"
            :key="column"
            scope="col"
            class="px-4 py-3 text-start font-medium text-n-slate-11 capitalize whitespace-nowrap"
          >
            {{ label(column) }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(row, index) in table.rows"
          :key="index"
          class="border-t border-n-weak"
        >
          <td
            v-for="column in table.columns"
            :key="column"
            class="px-4 py-3 text-n-slate-12 tabular-nums whitespace-nowrap"
          >
            {{ cell(row[column]) }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
