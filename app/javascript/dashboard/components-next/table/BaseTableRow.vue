<script setup>
defineProps({
  item: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <tr>
    <slot :item="item" />
  </tr>
</template>
