<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    :width="size"
    :height="size"
    :fill="color"
    viewBox="0 0 256 256"
  >
    <path
      d="M128,176a48.05,48.05,0,0,0,48-48V64a48,48,0,0,0-96,0v64A48.05,48.05,0,0,0,128,176ZM96,64a32,32,0,0,1,64,0v64a32,32,0,0,1-64,0Zm40,143.6V240a8,8,0,0,1-16,0V207.6A80.11,80.11,0,0,1,48,128a8,8,0,0,1,16,0,64,64,0,0,0,128,0,8,8,0,0,1,16,0A80.11,80.11,0,0,1,136,207.6Z"
    />
  </svg>
</template>
<script>
export default {
  props: {
    color: {
      type: String,
      required: true,
      default: 'currentColor',
    },
    size: {
      type: [String, Number],
      default: '20',
    },
  },

  computed: {
    pathSource() {
      // To support icons with multiple paths
      const path = this.icons[`${this.icon}-${this.type}`];
      if (path.constructor === Array) {
        return path;
      }
      return [path];
    },
  },
};
</script>
