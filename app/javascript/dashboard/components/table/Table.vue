<script setup>
import { FlexRender } from '@tanstack/vue-table';
import SortButton from './SortButton.vue';
import { computed } from 'vue';

const props = defineProps({
  table: {
    type: Object,
    required: true,
  },
  type: {
    type: String,
    default: 'relaxed',
  },
  customHeaderClass: {
    type: String,
    default: '',
  },
  customCellClass: {
    type: String,
    default: '',
  },
});

const isRelaxed = computed(() => props.type === 'relaxed');
const headerClass = computed(() =>
  isRelaxed.value
    ? 'ltr:first:rounded-bl-lg ltr:first:rounded-tl-lg ltr:last:rounded-br-lg ltr:last:rounded-tr-lg rtl:first:rounded-br-lg rtl:first:rounded-tr-lg rtl:last:rounded-bl-lg rtl:last:rounded-tl-lg'
    : ''
);

const cellClass = computed(() => {
  const base = 'overflow-hidden text-ellipsis break-words hyphens-auto';
  const padding = isRelaxed.value ? 'py-4 px-5' : 'py-2 px-5';
  return `${base} ${padding} ${props.customCellClass}`;
});
</script>

<template>
  <div class="w-full overflow-hidden">
    <table class="w-full table-fixed break-words">
      <thead class="sticky top-0 z-10 bg-n-slate-1">
        <tr
          v-for="headerGroup in table.getHeaderGroups()"
          :key="headerGroup.id"
          class="rounded-xl"
        >
          <th
            v-for="header in headerGroup.headers"
            :key="header.id"
            class="text-left py-3 px-5 font-medium text-sm text-n-slate-12 overflow-hidden text-ellipsis break-words hyphens-auto"
            :class="[headerClass, customHeaderClass]"
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
              <SortButton
                v-if="header.column.getCanSort()"
                :header="header"
                class="w-3 h-3 flex-shrink-0"
              />
            </div>
          </th>
        </tr>
      </thead>

      <tbody class="divide-y divide-n-slate-2">
        <tr v-for="row in table.getRowModel().rows" :key="row.id">
          <td
            v-for="cell in row.getVisibleCells()"
            :key="cell.id"
            :class="cellClass"
          >
            <FlexRender
              :render="cell.column.columnDef.cell"
              :props="cell.getContext()"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
