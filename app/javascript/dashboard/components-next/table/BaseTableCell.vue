<script setup>
defineProps({
  align: {
    type: String,
    default: 'start',
    validator: value => ['start', 'center', 'end'].includes(value),
  },
});
</script>

<template>
  <td
    class="py-3 ltr:pr-4 rtl:pl-4 text-body-main"
    :class="{
      'text-start': align === 'start',
      'text-center': align === 'center',
      'text-end': align === 'end',
    }"
  >
    <slot />
  </td>
</template>
