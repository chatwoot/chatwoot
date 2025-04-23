<script>
export default {
  name: 'Activity',
  props: {
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      cardData: this.data || {},
    };
  },
};
</script>

<template>
  <p class="italic text-xs">
    {{ cardData.text }}
  </p>
</template>
