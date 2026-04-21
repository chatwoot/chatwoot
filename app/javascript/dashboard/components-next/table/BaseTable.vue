<script setup>
import { computed } from 'vue';

const props = defineProps({
  headers: {
    type: Array,
    default: () => [],
  },
  items: {
    type: Array,
    default: () => [],
  },
  noDataMessage: {
    type: String,
    default: '',
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const hasHeaderSlot = computed(() => !!props.headers.length);
const showHeaders = computed(
  () => hasHeaderSlot.value && props.items.length > 0
);
</script>

<template>
  <div class="w-full">
    <table class="min-w-full table-auto divide-y divide-s-border">
      <thead v-if="showHeaders" class="border-t border-s-border">
        <tr>
          <th
            v-for="(header, index) in headers"
            :key="index"
            class="py-4 ltr:pr-4 rtl:pl-4 text-start text-heading-3 text-s-primary capitalize"
          >
            <slot :name="`header-${index}`" :header="header">
              {{ header }}
            </slot>
          </th>
        </tr>
      </thead>
      <tbody class="divide-y divide-s-border text-s-muted">
        <template v-if="items.length">
          <slot name="row" :items="items" />
        </template>
        <tr v-else-if="noDataMessage && !loading">
          <td
            :colspan="headers.length || 1"
            class="py-20 text-center text-body-main !text-base text-s-muted"
          >
            {{ noDataMessage }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
