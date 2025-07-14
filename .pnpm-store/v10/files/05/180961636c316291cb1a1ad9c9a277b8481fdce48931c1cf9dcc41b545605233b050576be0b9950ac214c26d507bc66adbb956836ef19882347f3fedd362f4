<script lang="ts" setup>
import { reactive } from 'vue'

const progress = reactive({
  loaded: 0,
  total: 0,
})

const maxCols = window.innerWidth / 20

if (import.meta.hot) {
  import.meta.hot.on('histoire:stories-loading-progress', (data) => {
    progress.loaded = data.loadedFileCount
    progress.total = data.totalFileCount
  })
}
</script>

<template>
  <div class="histoire-initial-loading htw-fixed htw-inset-0 htw-bg-white dark:htw-bg-gray-700 htw-flex htw-flex-col htw-gap-6 htw-items-center htw-justify-center">
    <transition name="__histoire-fade">
      <div
        v-if="progress.total > 0"
        class="htw-grid htw-gap-2"
        :style="{
          gridTemplateColumns: `repeat(${Math.min(Math.ceil(Math.sqrt(progress.total)), maxCols)}, minmax(0, 1fr))`,
        }"
      >
        <div
          v-for="n in progress.total"
          :key="n"
          class="htw-bg-primary-500/10 htw-rounded-full"
        >
          <div
            class="htw-w-3 htw-h-3 htw-bg-primary-500 htw-rounded-full htw-duration-150 htw-ease-out"
            :class="{
              'htw-transition-transform htw-scale-0': n >= progress.loaded,
            }"
          />
        </div>
      </div>
    </transition>
  </div>
</template>
