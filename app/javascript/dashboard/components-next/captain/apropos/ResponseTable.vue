<script setup>
import { computed, h } from 'vue';
import { useI18n } from 'vue-i18n';
import { getCoreRowModel, useVueTable } from '@tanstack/vue-table';
import Table from 'dashboard/components/table/Table.vue';
import ResponseTableCell from './ResponseTableCell.vue';

const props = defineProps({ table: { type: Object, required: true } });
const { t } = useI18n();
const columns = computed(() =>
  props.table.columns.map(value => {
    const column =
      typeof value === 'string' ? { key: value, type: 'text' } : value;
    return {
      id: column.key,
      accessorFn: row => row[column.key],
      header: column.label || column.key.replace(/[_-]/g, ' '),
      cell: context =>
        h(ResponseTableCell, {
          value: context.getValue(),
          column,
          row: context.row.original,
        }),
    };
  })
);
const renderedTable = useVueTable({
  get data() {
    return props.table.rows;
  },
  get columns() {
    return columns.value;
  },
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
});
</script>

<template>
  <div
    class="ms-8 min-w-0 max-w-full max-h-[28rem] overflow-auto [contain:inline-size] rounded-xl border border-n-weak bg-n-solid-1"
    tabindex="0"
    role="region"
    :aria-label="t('CAPTAIN_ASK.TRACE.OUTPUT')"
  >
    <Table
      :table="renderedTable"
      type="compact"
      class="w-full text-body-main"
    />
  </div>
</template>
