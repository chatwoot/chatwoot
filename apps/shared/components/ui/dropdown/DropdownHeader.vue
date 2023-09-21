<template>
  <li class="inline-flex list-none" :tabindex="null" :aria-disabled="true">
    <span
      class="text-xs text-slate-600 dark:text-slate-100 mt-1 font-medium w-full block text-left rtl:text-right whitespace-nowrap p-2"
    >
      {{ title }}
    </span>
    <slot />
  </li>
</template>
<script>
export default {
  componentName: 'WootDropdownMenu',
  props: {
    title: {
      type: String,
      default: '',
    },
  },
};
</script>
