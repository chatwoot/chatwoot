<script setup>
import BaseSettingsListItem from '../../components/BaseSettingsListItem.vue';
</script>

<template>
  <BaseSettingsListItem class="opacity-50">
    <template #title>
      <div
        class="w-24 h-[26px] rounded-md bg-surface-container-highest animate-pulse"
      />
    </template>
    <template #description>
      <div
        class="w-64 h-4 mb-0.5 rounded-md bg-surface-container-highest animate-pulse"
      />
      <div
        class="w-48 h-4 rounded-md bg-surface-container-highest animate-pulse"
      />
    </template>
    <template #label>
      <div
        class="w-32 h-[26px] bg-surface-container-highest animate-pulse rounded-md"
      />
    </template>
    <template #rightSection>
      <div
        class="flex items-center sm:rtl:!border-l-0 sm:rtl:!border-r border-outline-variant/15 gap-1.5 w-fit sm:w-full sm:gap-0 sm:justify-between"
      >
        <div
          v-for="ii in 3"
          :key="ii"
          class="flex justify-end w-1/3 h-full px-4"
        >
          <div
            class="w-32 h-full rounded-md bg-surface-container-highest animate-pulse"
          />
        </div>
      </div>
    </template>
  </BaseSettingsListItem>
</template>
