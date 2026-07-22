<script setup>
import { FlexRender } from '@tanstack/vue-table';
import SortButton from './SortButton.vue';
import { computed } from 'vue';

const props = defineProps({
  table: {
    type: Object,
    required: true,
  },
  fixed: {
    type: Boolean,
    default: false,
  },
  type: {
    type: String,
    default: 'relaxed',
  },
});

const isRelaxed = computed(() => props.type === 'relaxed');
const headerClass = computed(() =>
  isRelaxed.value
    ? 'ltr:first:rounded-bl-lg ltr:first:rounded-tl-lg ltr:last:rounded-br-lg ltr:last:rounded-tr-lg rtl:first:rounded-br-lg rtl:first:rounded-tr-lg rtl:last:rounded-bl-lg rtl:last:rounded-tl-lg'
    : ''
);

const stickyCellClass = (column, isHeader = false) => {
  const left = column.columnDef.meta?.stickyLeft;
  if (left == null) return '';
  return ['sticky z-[5]', isHeader ? 'bg-n-slate-1' : 'bg-n-solid-2'].join(' ');
};

const stickyCellStyle = column => {
  const left = column.columnDef.meta?.stickyLeft;
  if (left == null) return {};
  return { left };
};

const columnSizeStyle = column => {
  const size = column.getSize();
  const minSize = column.columnDef.minSize ?? size;
  return {
    width: `${size}px`,
    minWidth: `${minSize}px`,
  };
};
</script>

<template>
  <!-- w-max: grow with column sizes instead of crushing headers into a compact wrap -->
  <table class="w-max min-w-full" :class="{ 'table-fixed': fixed }">
    <thead class="sticky top-0 z-10 bg-n-slate-1">
      <tr
        v-for="headerGroup in table.getHeaderGroups()"
        :key="headerGroup.id"
        class="rounded-xl"
      >
        <th
          v-for="header in headerGroup.headers"
          :key="header.id"
          :style="{
            ...columnSizeStyle(header.column),
            ...stickyCellStyle(header.column),
          }"
          class="text-left font-medium text-sm text-n-slate-12"
          :class="[
            headerClass,
            isRelaxed ? 'py-4 px-4' : 'py-2 px-3',
            stickyCellClass(header.column, true),
          ]"
          @click="header.column.getCanSort() && header.column.toggleSorting()"
        >
          <div v-if="!header.isPlaceholder" class="flex items-center gap-1.5">
            <FlexRender
              :render="header.column.columnDef.header"
              :props="header.getContext()"
            />
            <SortButton v-if="header.column.getCanSort()" :header="header" />
          </div>
        </th>
      </tr>
    </thead>

    <tbody class="divide-y divide-n-slate-2">
      <tr v-for="row in table.getRowModel().rows" :key="row.id">
        <td
          v-for="cell in row.getVisibleCells()"
          :key="cell.id"
          :style="{
            ...columnSizeStyle(cell.column),
            ...stickyCellStyle(cell.column),
          }"
          :class="[
            isRelaxed ? 'py-4 px-4 text-sm' : 'py-2 px-3',
            stickyCellClass(cell.column),
          ]"
        >
          <FlexRender
            :render="cell.column.columnDef.cell"
            :props="cell.getContext()"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>
