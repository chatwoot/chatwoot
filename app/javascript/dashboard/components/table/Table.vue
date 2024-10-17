<script setup>
import { FlexRender } from '@tanstack/vue-table';
import SortButton from './SortButton.vue';

defineProps({
  table: {
    type: Object,
    required: true,
  },
  fixed: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <table :class="{ 'table-fixed': fixed }">
    <thead
      class="sticky top-0 z-10 border-b border-slate-50 dark:border-slate-800 bg-slate-25 dark:bg-slate-800"
    >
      <tr v-for="headerGroup in table.getHeaderGroups()" :key="headerGroup.id">
        <th
          v-for="header in headerGroup.headers"
          :key="header.id"
          :style="{
            width: `${header.getSize()}px`,
          }"
          class="text-left py-3 px-5 dark:bg-slate-800 text-slate-800 dark:text-slate-200 font-normal text-xs"
          @click="header.column.getCanSort() && header.column.toggleSorting()"
        >
          <div
            v-if="!header.isPlaceholder"
            class="flex place-items-center gap-1"
          >
            <FlexRender
              :render="header.column.columnDef.header"
              :props="header.getContext()"
            />
            <SortButton v-if="header.column.getCanSort()" :header="header" />
          </div>
        </th>
      </tr>
    </thead>

    <tbody class="divide-y divide-slate-25 dark:divide-slate-900">
      <tr
        v-for="row in table.getRowModel().rows"
        :key="row.id"
        class="hover:bg-slate-25 dark:hover:bg-slate-800"
      >
        <td
          v-for="cell in row.getVisibleCells()"
          :key="cell.id"
          class="py-2 px-5"
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
