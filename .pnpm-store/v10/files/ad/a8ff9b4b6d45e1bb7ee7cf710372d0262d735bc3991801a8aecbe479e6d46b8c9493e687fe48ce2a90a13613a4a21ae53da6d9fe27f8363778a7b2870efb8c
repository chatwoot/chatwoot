<script lang="ts" setup>
import type { Ref } from 'vue'
import { computed, onUnmounted, ref } from 'vue'
import { useEventListener } from '@vueuse/core'
import { Icon } from '@iconify/vue'
import { VTooltip as vTooltip } from 'floating-vue'
import HatchedPattern from '../misc/HatchedPattern.vue'
import CheckerboardPattern from '../misc/CheckerboardPattern.vue'
import { usePreviewSettingsStore } from '../../stores/preview-settings'
import type { Variant } from '../../types'

const props = defineProps<{
  variant: Variant
}>()

const settings = usePreviewSettingsStore().currentSettings

// Resize

const resizing = ref(false)

const onUnmountedCleanupFns: (() => unknown)[] = []
onUnmounted(() => {
  onUnmountedCleanupFns.forEach(fn => fn())
})

function addWindowListener(event: string, listener: (event: any) => unknown) {
  window.addEventListener(event, listener)
  const removeListener = () => window.removeEventListener(event, listener)
  onUnmountedCleanupFns.push(removeListener)
  return () => {
    removeListener()
    onUnmountedCleanupFns.splice(onUnmountedCleanupFns.indexOf(removeListener), 1)
  }
}

function useDragger(el: Ref<HTMLDivElement>, value: Ref<number>, min: number, max: number, axis: 'x' | 'y') {
  function onMouseDown(event: MouseEvent) {
    event.preventDefault()
    event.stopPropagation()
    const start = axis === 'x' ? event.clientX : event.clientY
    const startValue = value.value ?? (axis === 'x' ? previewWrapper.value.clientWidth - 67 : previewWrapper.value.clientHeight - 70)
    resizing.value = true

    const removeListeners = [
      addWindowListener('mousemove', onMouseMove),
      addWindowListener('mouseup', onMouseUp),
    ]

    function onMouseMove(event: MouseEvent) {
      const snapTarget = (axis === 'x' ? previewWrapper.value.clientWidth : previewWrapper.value.clientHeight)
      const delta = (axis === 'x' ? event.clientX : event.clientY) - start
      value.value = Math.max(min, Math.min(max, startValue + delta))

      if (Math.abs(value.value - (snapTarget - 67)) < 16) {
        value.value = null
      }
    }

    function onMouseUp() {
      removeListeners.forEach(fn => fn())
      resizing.value = false
    }
  }
  useEventListener(el, 'mousedown', onMouseDown)

  function onTouchStart(event: TouchEvent) {
    event.preventDefault()
    event.stopPropagation()
    const start = axis === 'x' ? event.touches[0].clientX : event.touches[0].clientY
    const startValue = value.value
    resizing.value = true

    const removeListeners = [
      addWindowListener('touchmove', onTouchMove),
      addWindowListener('touchend', onTouchEnd),
      addWindowListener('touchcancel', onTouchEnd),
    ]

    function onTouchMove(event: TouchEvent) {
      const delta = (axis === 'x' ? event.touches[0].clientX : event.touches[0].clientY) - start
      value.value = Math.max(min, Math.min(max, startValue + delta))
    }

    function onTouchEnd() {
      removeListeners.forEach(fn => fn())
      resizing.value = false
    }
  }
  useEventListener(el, 'touchstart', onTouchStart)
}

const responsiveWidth = computed({
  get: () => settings[settings.rotate ? 'responsiveHeight' : 'responsiveWidth'],
  set: (value) => { settings[settings.rotate ? 'responsiveHeight' : 'responsiveWidth'] = value },
})
const responsiveHeight = computed({
  get: () => settings[settings.rotate ? 'responsiveWidth' : 'responsiveHeight'],
  set: (value) => { settings[settings.rotate ? 'responsiveWidth' : 'responsiveHeight'] = value },
})

const horizontalDragger = ref<HTMLDivElement>()
const verticalDragger = ref<HTMLDivElement>()
const cornerDragger = ref<HTMLDivElement>()
const previewWrapper = ref<HTMLDivElement>()

useDragger(horizontalDragger, responsiveWidth, 32, 20000, 'x')
useDragger(verticalDragger, responsiveHeight, 32, 20000, 'y')
useDragger(cornerDragger, responsiveWidth, 32, 20000, 'x')
useDragger(cornerDragger, responsiveHeight, 32, 20000, 'y')

// Handle rotate

const finalWidth = computed(() => settings.rotate ? settings.responsiveHeight : settings.responsiveWidth)
const finalHeight = computed(() => settings.rotate ? settings.responsiveWidth : settings.responsiveHeight)

// Disabled responsive

const isResponsiveEnabled = computed(() => !props.variant.responsiveDisabled)

const sizeTooltip = computed(() => `${responsiveWidth.value ?? 'Auto'} × ${responsiveHeight.value ?? 'Auto'}`)
</script>

<template>
  <div class="histoire-story-responsive-preview htw-w-full htw-h-full htw-flex-1 htw-rounded-lg htw-relative htw-overflow-hidden">
    <div
      v-if="isResponsiveEnabled"
      class="htw-absolute htw-inset-0 htw-w-full htw-h-full htw-bg-gray-100 dark:htw-bg-gray-750 htw-rounded-r-lg htw-border-l-2 htw-border-gray-500/10 dark:htw-border-gray-700/30 htw-overflow-hidden"
    >
      <HatchedPattern
        class="htw-w-full htw-h-full htw-text-black/[1%] dark:htw-text-white/[1%]"
      />
    </div>

    <div
      ref="previewWrapper"
      class="htw-h-full htw-overflow-auto htw-relative"
    >
      <div
        class="htw-overflow-hidden htw-bg-white dark:htw-bg-gray-700 htw-rounded-lg htw-relative"
        :class="isResponsiveEnabled ? {
          'htw-w-fit': !!finalWidth,
          'htw-h-fit': !!finalHeight,
          'htw-h-full': !finalHeight,
        } : 'htw-h-full'"
      >
        <div
          class="bind-preview-bg htw-rounded-lg htw-h-full"
          data-test-id="responsive-preview-bg"
        >
          <CheckerboardPattern
            v-if="settings.checkerboard"
            class="htw-absolute htw-inset-0 htw-w-full htw-h-full htw-text-gray-500/20"
          />
          <div class="htw-p-8 htw-h-full htw-relative">
            <div class="htw-w-full htw-h-full htw-relative">
              <div class="htw-absolute htw-inset-0" />

              <slot
                :is-responsive-enabled="isResponsiveEnabled"
                :final-width="finalWidth"
                :final-height="finalHeight"
                :resizing="resizing"
              />
            </div>

            <!-- Markers -->
            <div class="htw-absolute htw-top-5 htw-left-8 htw-h-2 htw-w-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-top-5 htw-right-8 htw-h-2 htw-w-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-bottom-5 htw-left-8 htw-h-2 htw-w-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-bottom-5 htw-right-8 htw-h-2 htw-w-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-left-5 htw-top-8 htw-w-2 htw-h-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-left-5 htw-bottom-8 htw-w-2 htw-h-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-right-5 htw-top-8 htw-w-2 htw-h-px htw-bg-gray-400/25" />
            <div class="htw-absolute htw-right-5 htw-bottom-8 htw-w-2 htw-h-px htw-bg-gray-400/25" />
          </div>

          <!-- Resize Dragger -->
          <template v-if="isResponsiveEnabled">
            <div
              ref="horizontalDragger"
              v-tooltip.right="sizeTooltip"
              class="htw-absolute htw-w-4 htw-top-0 htw-bottom-4 htw-right-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-ew-resize htw-group hover:htw-text-primary-500"
            >
              <Icon
                icon="mdi:drag-vertical-variant"
                class="htw-w-4 htw-h-4 htw-opacity-20 group-hover:htw-opacity-90"
              />
            </div>
            <div
              ref="verticalDragger"
              v-tooltip.bottom="sizeTooltip"
              class="htw-absolute htw-h-4 htw-left-0 htw-right-4 htw-bottom-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-ns-resize htw-group hover:htw-text-primary-500"
            >
              <Icon
                icon="mdi:drag-horizontal-variant"
                class="htw-w-4 htw-h-4 htw-opacity-20 group-hover:htw-opacity-90"
              />
            </div>
            <div
              ref="cornerDragger"
              v-tooltip.bottom="sizeTooltip"
              class="htw-absolute htw-w-4 htw-h-4 htw-right-0 htw-bottom-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-nwse-resize htw-group hover:htw-text-primary-500"
            />
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.bind-preview-bg {
  background-color: v-bind('settings.backgroundColor');
}
</style>
