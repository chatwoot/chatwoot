<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  inheritAttrs: false,

  props: {
    exact: {
      type: Boolean,
      default: false,
    },

    matched: {
      type: Boolean,
      default: null,
    },
  },
})
</script>

<template>
  <router-link
    v-slot="{ isActive, isExactActive, href, navigate }"
    class="histoire-base-overflow-tab"
    v-bind="$attrs"
    custom
  >
    <a
      v-bind="$attrs"
      :href="href"
      class="htw-px-4 htw-h-10 htw-min-w-[150px] htw-inline-flex htw-items-center hover:htw-bg-primary-50 dark:hover:htw-bg-primary-900 htw-relative htw-text-gray-900 dark:htw-text-gray-100"
      :class="{
        'htw-text-primary-500 dark:htw-text-primary-400': matched != null ? matched : (exact && isExactActive) || (!exact && isActive),
      }"
      @click="navigate"
    >
      <slot />

      <transition name="__histoire-scale-y">
        <div
          v-if="matched != null ? matched : (exact && isExactActive) || (!exact && isActive)"
          class="htw-absolute htw-top-0 htw-left-0 htw-h-full htw-w-[2px] htw-bg-primary-500 dark:htw-bg-primary-400"
        />
      </transition>
    </a>
  </router-link>
</template>
