<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { computed } from 'vue'
import { usePreviewSettingsStore } from '../../stores/preview-settings'
import { histoireConfig } from '../../util/config'
import { getContrastColor } from '../../util/preview-settings'
import BaseCheckbox from '../base/BaseCheckbox.vue'

const settings = usePreviewSettingsStore().currentSettings

const contrastColor = computed(() => getContrastColor(settings))
</script>

<template>
  <VDropdown
    v-if="histoireConfig.backgroundPresets.length"
    placement="bottom-end"
    :skidding="6"
    class="histoire-toolbar-background htw-h-full htw-flex-none"
    data-test-id="toolbar-background"
  >
    <div
      v-tooltip="'Background color'"
      class="htw-cursor-pointer hover:htw-text-primary-500 htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 htw-group"
    >
      <div
        class="bind-preview-bg htw-w-4 htw-h-4 htw-rounded-full htw-border htw-border-black/50 dark:htw-border-white/50 htw-flex htw-items-center htw-justify-center htw-text-xs"
      >
        <span v-if="contrastColor">a</span>
      </div>
      <Icon
        icon="carbon:caret-down"
        class="htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
      />
    </div>

    <template #popper="{ hide }">
      <div
        class="htw-flex htw-flex-col htw-items-stretch"
        data-test-id="background-popper"
      >
        <BaseCheckbox v-model="settings.checkerboard">
          Checkerboard
        </BaseCheckbox>

        <button
          v-for="(option, index) in histoireConfig.backgroundPresets"
          :key="index"
          class="htw-px-4 htw-py-3 htw-cursor-pointer htw-text-left htw-flex htw-items-baseline htw-gap-4"
          :class="[
            settings.backgroundColor === option.color
              ? 'htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black'
              : 'htw-bg-transparent hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700',
          ]"
          @click="settings.backgroundColor = option.color;hide()"
        >
          <span class="htw-mr-auto">{{ option.label }}</span>
          <template v-if="option.color !== '$checkerboard'">
            <span class="htw-ml-auto htw-opacity-70">{{ option.color }}</span>
            <div
              class="htw-w-4 htw-h-4 htw-rounded-full htw-border htw-border-black/20 dark:htw-border-white/20 htw-flex htw-items-center htw-justify-center htw-text-xs"
              :style="{
                backgroundColor: option.color,
                color: option.contrastColor,
              }"
            >
              <span v-if="option.contrastColor">a</span>
            </div>
          </template>
        </button>
      </div>
    </template>
  </VDropdown>
</template>

<style scoped>
.bind-preview-bg {
  background-color: v-bind('settings.backgroundColor');
  color: v-bind('contrastColor');
}
</style>
