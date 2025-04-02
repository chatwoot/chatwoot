<script setup>
import BaseSettingsListItem from '../../components/BaseSettingsListItem.vue';
import SLAResponseTime from './SLAResponseTime.vue';
import SLABusinessHoursLabel from './SLABusinessHoursLabel.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  slaName: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  firstResponse: {
    type: String,
    required: true,
  },
  nextResponse: {
    type: String,
    required: true,
  },
  resolutionTime: {
    type: String,
    required: true,
  },
  hasBusinessHours: {
    type: Boolean,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete']);
</script>

<template>
  <BaseSettingsListItem
    class="sm:divide-x sm:divide-slate-75 sm:dark:divide-slate-700/50"
    :title="slaName"
    :description="description"
  >
    <template #label>
      <SLABusinessHoursLabel :has-business-hours="hasBusinessHours" />
    </template>
    <template #rightSection>
      <div
        class="flex items-center divide-x rtl:divide-x-reverse sm:rtl:!border-l-0 sm:rtl:!border-r sm:rtl:border-solid sm:rtl:border-slate-75 sm:rtl:dark:border-slate-700/50 gap-1.5 w-fit sm:w-full sm:gap-0 sm:justify-between divide-slate-75 dark:divide-slate-700/50"
      >
        <SLAResponseTime response-type="FRT" :response-time="firstResponse" />
        <SLAResponseTime response-type="NRT" :response-time="nextResponse" />
        <SLAResponseTime response-type="RT" :response-time="resolutionTime" />
      </div>
    </template>
    <template #actions>
      <Button
        v-tooltip.top="$t('SLA.FORM.DELETE')"
        faded
        ruby
        xs
        icon="i-lucide-trash-2"
        :is-loading="isLoading"
        @click="emit('delete')"
      />
    </template>
  </BaseSettingsListItem>
</template>
