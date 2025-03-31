<script lang="ts" setup>
import { computed, onUnmounted, ref, watch } from 'vue'

const SAVE_PREFIX = '__histoire'

const props = defineProps({
  orientation: {
    type: String,
    default: 'landscape',
    validator: (value: string) => ['landscape', 'portrait'].includes(value),
  },

  defaultSplit: {
    type: Number,
    default: 50,
  },

  split: {
    type: Number,
    default: undefined,
  },

  min: {
    type: Number,
    default: 20,
  },

  max: {
    type: Number,
    default: 80,
  },

  draggerOffset: {
    type: String,
    default: 'center',
    validator: (value: string) => ['before', 'center', 'after'].includes(value),
  },

  saveId: {
    type: String,
    default: null,
  },

  fixed: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  'update:split': (_value: number) => true,
})

const currentSplit = ref(props.defaultSplit)

watch(() => props.split, (value) => {
  if (value !== undefined) {
    currentSplit.value = value
  }
}, {
  immediate: true,
})

if (props.saveId) {
  const storageKey = `${SAVE_PREFIX}-split-pane-${props.saveId}`

  const savedValue = localStorage.getItem(storageKey)
  if (savedValue != null) {
    let parsedValue
    try {
      parsedValue = JSON.parse(savedValue)
    }
    catch (e) {
      console.error(e)
    }

    if (typeof parsedValue === 'number') {
      currentSplit.value = parsedValue
    }
  }

  watch(currentSplit, (value) => {
    localStorage.setItem(storageKey, JSON.stringify(value))
  })

  watch(currentSplit, (value) => {
    if (value !== props.split) {
      emit('update:split', value)
    }
  }, {
    immediate: true,
  })
}

const boundSplit = computed(() => {
  if (currentSplit.value < props.min) {
    return props.min
  }
  else if (currentSplit.value > props.max) {
    return props.max
  }
  else {
    return currentSplit.value
  }
})

const leftStyle = computed(() => ({
  [props.orientation === 'landscape' ? 'width' : 'height']: props.fixed ? `${boundSplit.value}px` : `${boundSplit.value}%`,
}))

const rightStyle = computed(() => ({
  [props.orientation === 'landscape' ? 'width' : 'height']: props.fixed ? null : `${100 - boundSplit.value}%`,
}))

const dragging = ref(false)
let startPosition = 0
let startSplit = 0
const el = ref(null)

function dragStart(e) {
  dragging.value = true
  startPosition = props.orientation === 'landscape' ? e.pageX : e.pageY
  startSplit = boundSplit.value
  window.addEventListener('mousemove', dragMove)
  window.addEventListener('mouseup', dragEnd)
}

function dragMove(e) {
  if (dragging.value) {
    let position
    let totalSize
    if (props.orientation === 'landscape') {
      position = e.pageX
      totalSize = el.value.offsetWidth
    }
    else {
      position = e.pageY
      totalSize = el.value.offsetHeight
    }
    const dPosition = position - startPosition
    if (props.fixed) {
      currentSplit.value = startSplit + dPosition
    }
    else {
      currentSplit.value = startSplit + ~~(dPosition / totalSize * 200) / 2
    }
  }
}

function dragEnd() {
  dragging.value = false
  removeDragListeners()
}

function removeDragListeners() {
  window.removeEventListener('mousemove', dragMove)
  window.removeEventListener('mouseup', dragEnd)
}

onUnmounted(() => {
  removeDragListeners()
})
</script>

<template>
  <div
    ref="el"
    class="histoire-base-split-pane htw-flex htw-h-full htw-isolate htw-overflow-auto"
    :class="{
      'htw-flex-col': orientation === 'portrait',
      'htw-cursor-ew-resize': dragging && orientation === 'landscape',
      'htw-cursor-ns-resize': dragging && orientation === 'portrait',
      [orientation]: true,
    }"
  >
    <div
      class="htw-relative htw-top-0 htw-left-0 htw-z-20"
      :class="{
        'htw-pointer-events-none': dragging,
        'htw-border-r htw-border-gray-300/30 dark:htw-border-gray-800': orientation === 'landscape',
        'htw-flex-none': fixed,
      }"
      :style="leftStyle"
    >
      <slot name="first" />

      <div
        class="dragger htw-absolute htw-z-100 hover:htw-bg-primary-500/50 htw-transition-colors htw-duration-150 htw-delay-150"
        :class="{
          'htw-top-0 htw-bottom-0 htw-cursor-ew-resize': orientation === 'landscape',
          'htw-left-0 htw-right-0 htw-cursor-ns-resize': orientation === 'portrait',
          [`dragger-offset-${draggerOffset}`]: true,
          'htw-bg-primary-500/25': dragging,
        }"
        @mousedown.prevent="dragStart"
      />
    </div>
    <div
      class="htw-relative htw-bottom-0 htw-right-0"
      :class="{
        'htw-pointer-events-none': dragging,
        'htw-border-t htw-border-gray-300/30 dark:htw-border-gray-800': orientation === 'portrait',
        'htw-flex-1': fixed,
      }"
      :style="rightStyle"
    >
      <slot name="last" />
    </div>
  </div>
</template>

<style lang="postcss" scoped>
.landscape > div > .dragger {
  width: .625rem;
}

.portrait > div > .dragger {
  height: .625rem;
}

.landscape > div > .dragger.dragger-offset-before {
  right: 0;
}

.portrait > div > .dragger.dragger-offset-before {
  bottom: 0;
}

.landscape > div > .dragger.dragger-offset-center {
  right: -.3125rem;
}

.portrait > div > .dragger.dragger-offset-center {
  bottom: -.3125rem;
}

.landscape > div > .dragger.dragger-offset-after {
  right: -.625rem;
}

.portrait > div > .dragger.dragger-offset-after {
  bottom: -.625rem;
}
</style>
