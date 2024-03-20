<script setup>
import BaseSettingsListItem from '../../components/BaseSettingsListItem.vue';
import SLAResponseTime from './SLAResponseTime.vue';

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
  inBusinessHours: {
    type: Boolean,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>
<template>
  <base-settings-list-item
    :title="slaName"
    :description="description"
    :has-actions="true"
  >
    <template #label>
      <div
        class="inline-flex items-center gap-1 px-1.5 sm:px-2 py-1 border border-solid rounded-lg border-slate-75 dark:border-slate-700/50"
      >
        <fluent-icon
          size="14"
          :icon="inBusinessHours ? 'alarm-on' : 'alarm-off'"
          type="outline"
          class="flex-shrink-0"
          :class="
            inBusinessHours
              ? 'text-slate-600 dark:text-slate-500'
              : 'text-slate-300 dark:text-slate-700/50 sm:text-slate-600 sm:dark:text-slate-500'
          "
        />
        <span
          class="hidden text-xs font-normal sm:block text-slate-600 dark:text-slate-300"
        >
          {{
            inBusinessHours
              ? $t('SLA.LIST.BUSINESS_HOURS_ON')
              : $t('SLA.LIST.BUSINESS_HOURS_OFF')
          }}
        </span>
      </div>
    </template>
    <template #rightSection>
      <div
        class="flex items-center gap-1.5 divide-x w-fit sm:w-full sm:gap-0 sm:justify-between divide-slate-75 dark:divide-slate-700/50"
      >
        <SLA-response-time response-type="FRT" :response-time="firstResponse" />
        <SLA-response-time response-type="NRT" :response-time="nextResponse" />
        <SLA-response-time response-type="RT" :response-time="resolutionTime" />
      </div>
    </template>
    <template #actions>
      <woot-button
        v-tooltip.top="$t('SLA.FORM.DELETE')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="delete"
        class-names="grey-btn"
        :is-loading="isLoading"
        @click="$emit('click')"
      />
    </template>
  </base-settings-list-item>
</template>
