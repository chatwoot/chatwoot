<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import { useMapGetter } from 'dashboard/composables/store';
defineProps({
  row: {
    type: Object,
    required: true,
  },
});
const isRTL = useMapGetter('accounts/isRTL');
// Function to get bot type label
function getBotTypeLabel(type) {
  const typeLabels = {
    'single': 'Single Agent',
    'multi': 'Multi Agent', 
    'custom': 'Custom Agent'
  };
  return typeLabels[type] || type;
}
// Function to get template type label
function getTemplateTypeLabel(template) {
  const templateLabels = {
    'booking': 'Booking',
    'resto': 'Restaurant',
    'sales': 'Sales',
    'cs': 'Customer Service'
  };
  return templateLabels[template] || template;
}
</script>

<template>
  <BaseCell>
    <div
      class="items-center flex text-left"
      :class="{ 'flex-row-reverse': isRTL }"
    >
      <div class="items-start flex flex-col min-w-0 my-0 mx-2">
        <h6
          class="overflow-hidden text-sm m-0 leading-[1.2] text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis"
        >
          {{ row.original.botName }}
        </h6>
        <div class="flex gap-2 text-xs text-slate-600 dark:text-slate-200">
          <span>{{ getBotTypeLabel(row.original.botType) }}</span>
          <span v-if="row.original.templateType && row.original.botType !== 'custom'" class="text-blue-600 dark:text-blue-400">
            • {{ getTemplateTypeLabel(row.original.templateType) }}
          </span>
        </div>
      </div>
    </div>
  </BaseCell>
</template>