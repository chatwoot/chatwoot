<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { usePreviewSettingsStore } from '../../stores/preview-settings'
import { histoireConfig } from '../../util/config'
import BaseCheckbox from '../base/BaseCheckbox.vue'

const settings = usePreviewSettingsStore().currentSettings
</script>

<template>
  <!-- Responsive size -->
  <VDropdown
    placement="bottom-end"
    :skidding="6"
    :disabled="!histoireConfig.responsivePresets?.length"
    class="histoire-toolbar-responsive-size htw-h-full htw-flex-none"
  >
    <div
      v-tooltip="'Responsive sizes'"
      class="htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 htw-group"
      :class="{
        'htw-cursor-pointer hover:htw-text-primary-500': histoireConfig.responsivePresets?.length,
      }"
    >
      <Icon
        icon="carbon:devices"
        class="htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
      />
      <Icon
        icon="carbon:caret-down"
        class="htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
      />
    </div>

    <template #popper="{ hide }">
      <div class="htw-flex htw-flex-col htw-items-stretch">
        <BaseCheckbox v-model="settings.rotate">
          Rotate
        </BaseCheckbox>

        <div class="htw-flex htw-items-center htw-gap-2 htw-px-4 htw-py-3">
          <input
            v-model.number="settings.responsiveWidth"
            v-tooltip="'Responsive width (px)'"
            type="number"
            class="htw-bg-transparent htw-border htw-border-gray-200 dark:htw-border-gray-850 htw-rounded htw-w-20 htw-opacity-50 focus:htw-opacity-100 htw-flex-1 htw-min-w-0"
            step="16"
            placeholder="Auto"
          >
          <span class="htw-opacity-50">×</span>
          <input
            v-model.number="settings.responsiveHeight"
            v-tooltip="'Responsive height (px)'"
            type="number"
            class="htw-bg-transparent htw-border htw-border-gray-200 dark:htw-border-gray-850 htw-rounded htw-w-20 htw-opacity-50 focus:htw-opacity-100 htw-flex-1 htw-min-w-0"
            step="16"
            placeholder="Auto"
          >
        </div>

        <button
          v-for="(preset, index) in histoireConfig.responsivePresets"
          :key="index"
          class="htw-px-4 htw-py-3 htw-cursor-pointer htw-text-left htw-flex htw-gap-4"
          :class="[
            settings.responsiveWidth === preset.width && settings.responsiveHeight === preset.height
              ? 'htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black'
              : 'htw-bg-transparent hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700',
          ]"
          @click="settings.responsiveWidth = preset.width;settings.responsiveHeight = preset.height;hide()"
        >
          {{ preset.label }}
          <span class="htw-ml-auto htw-opacity-70 htw-flex htw-gap-1">
            <span v-if="preset.width">{{ preset.width }}<span v-if="!preset.height">px</span></span>
            <span v-if="preset.width && preset.height">x</span>
            <span v-if="preset.height">{{ preset.height }}<span v-if="!preset.width">px</span></span>
          </span>
        </button>
      </div>
    </template>
  </VDropdown>
</template>
