<script lang="ts" setup>
defineProps<{
  isActive?: boolean
}>()

const emit = defineEmits<{
  (e: 'navigate'): void
}>()

function handleNavigate() {
  emit('navigate')
}
</script>

<template>
  <a
    class="istoire-base-list-ite htw-flex htw-items-center htw-gap-2 htw-text-gray-900 dark:htw-text-gray-100"
    :class="[
      $attrs.class,
      isActive
        ? 'active htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black'
        : 'hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900',
    ]"
    @click="handleNavigate()"
    @keyup.enter="handleNavigate()"
    @keyup.space="handleNavigate()"
  >
    <slot />
  </a>
</template>
