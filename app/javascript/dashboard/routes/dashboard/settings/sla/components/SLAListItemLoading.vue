<script setup>
import BaseSettingsListItem from '../../components/BaseSettingsListItem.vue';
</script>
<template>
  <base-settings-list-item class="opacity-50">
    <template #title>
      <div
        class="w-24 h-[26px] rounded-md bg-slate-50 dark:bg-slate-700 animate-pulse"
      />
    </template>
    <template #description>
      <div
        class="w-64 h-4 mb-0.5 rounded-md bg-slate-50 dark:bg-slate-700 animate-pulse"
      />
      <div
        class="w-48 h-4 rounded-md bg-slate-50 dark:bg-slate-700 animate-pulse"
      />
    </template>
    <template #label>
      <div
        class="w-32 h-[26px] bg-slate-50 dark:bg-slate-700 animate-pulse rounded-md"
      />
    </template>
    <template #rightSection>
      <div
        class="flex items-center sm:rtl:!border-l-0 sm:rtl:!border-r sm:rtl:border-solid sm:rtl:border-slate-75 sm:rtl:dark:border-slate-700/50 gap-1.5 w-fit sm:w-full sm:gap-0 sm:justify-between"
      >
        <div
          v-for="ii in 3"
          :key="ii"
          class="flex justify-end w-1/3 h-full px-4"
        >
          <div
            class="w-32 h-full rounded-md bg-slate-50 dark:bg-slate-700 animate-pulse"
          />
        </div>
      </div>
    </template>
  </base-settings-list-item>
</template>
