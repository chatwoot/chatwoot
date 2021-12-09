<template>
  <svg
    :width="size"
    :height="size"
    fill="none"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path :d="icons[`${icon}-${type}`]" fill="currentColor" />
  </svg>
</template>
<script>
import icons from './icons.json';

export default {
  name: 'FluentIcon',
  props: {
    icon: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      default: '20px',
    },
    type: {
      type: String,
      default: 'outline',
    },
  },
  data() {
    return { icons };
  },
};
</script>
