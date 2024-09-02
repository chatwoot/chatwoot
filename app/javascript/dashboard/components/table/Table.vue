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
    <thead>
      <tr v-for="headerGroup in table.getHeaderGroups()" :key="headerGroup.id">
        <th
          v-for="header in headerGroup.headers"
          :key="header.id"
          :style="{
            width: `${header.getSize()}px`,
          }"
          @click="header.column.getToggleSortingHandler()?.($event)"
        >
          <template v-if="!header.isPlaceholder">
            <FlexRender
              :render="header.column.columnDef.header"
              :props="header.getContext()"
            />
            <SortButton v-if="header.column.getCanSort()" :header="header" />
            <!--
              <ResizeHandle
                v-if="header.column.getCanResize()"
                :header="header"
              /> -->
          </template>
        </th>
      </tr>
    </thead>

    <tbody>
      <tr v-for="row in table.getRowModel().rows" :key="row.id">
        <td v-for="cell in row.getVisibleCells()" :key="cell.id" class="py-1">
          <FlexRender
            :render="cell.column.columnDef.cell"
            :props="cell.getContext()"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>
