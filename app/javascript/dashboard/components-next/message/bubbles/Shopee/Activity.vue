<script>
export default {
  name: 'Activity',
  props: {
    original: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <p class="italic text-xs">
    {{ original.text }}
  </p>
</template>
