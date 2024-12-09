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
    ? 'first:rounded-bl-lg first:rounded-tl-lg last:rounded-br-lg last:rounded-tr-lg'
    : ''
);
</script>

<template>
  <table :class="{ 'table-fixed': fixed }">
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
            width: `${header.getSize()}px`,
          }"
          class="text-left py-3 px-5 font-normal text-sm"
          :class="headerClass"
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

    <tbody class="divide-y divide-n-slate-2">
      <tr v-for="row in table.getRowModel().rows" :key="row.id">
        <td
          v-for="cell in row.getVisibleCells()"
          :key="cell.id"
          :class="isRelaxed ? 'py-4 px-5' : 'py-2 px-5'"
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
