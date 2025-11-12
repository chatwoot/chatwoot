<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  inheritAttrs: false,

  props: {
    isActive: {
      type: Boolean,
      default: undefined,
    },
  },

  emits: {
    navigate: () => true,
  },

  setup(props, { emit }) {
    function handleNavigate(event, navigate: (event) => unknown) {
      emit('navigate')
      navigate(event)
    }

    return {
      handleNavigate,
    }
  },
})
</script>

<template>
  <RouterLink
    v-slot="{ isActive: linkIsActive, href, navigate }"
    class="histoire-base-list-item-link"
    v-bind="$attrs"
    custom
  >
    <a
      :href="href"
      class="htw-flex htw-items-center htw-gap-2 htw-text-gray-900 dark:htw-text-gray-100"
      :class="[
        $attrs.class,
        (isActive != null ? isActive : linkIsActive)
          ? 'active htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black'
          : 'hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900',
      ]"
      @click="handleNavigate($event, navigate)"
      @keyup.enter="handleNavigate($event, navigate)"
      @keyup.space="handleNavigate($event, navigate)"
    >
      <slot
        :active="isActive != null ? isActive : linkIsActive"
      />
    </a>
  </RouterLink>
</template>
