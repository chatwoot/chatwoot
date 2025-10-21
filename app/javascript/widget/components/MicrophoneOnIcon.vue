<script>
export default {
  name: 'MicrophoneOnIcon',
  props: {
    size: {
      type: [String, Number],
      default: 24,
    },
    color: {
      type: String,
      default: null,
    },
    className: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <svg
    :width="size"
    :height="size"
    fill="none"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
    :class="className"
  >
    <path
      d="M12 2a4 4 0 0 1 4 4v6a4 4 0 0 1-8 0V6a4 4 0 0 1 4-4Zm0 1.5A2.5 2.5 0 0 0 9.5 6v6a2.5 2.5 0 0 0 5 0V6A2.5 2.5 0 0 0 12 3.5ZM5.75 11a.75.75 0 0 1 .75.75v.5A5.25 5.25 0 0 0 11.75 17.5h.5A5.25 5.25 0 0 0 17.5 12.25v-.5a.75.75 0 0 1 1.5 0v.5A6.75 6.75 0 0 1 12.75 19v2.25a.75.75 0 0 1-1.5 0V19A6.75 6.75 0 0 1 5 12.25v-.5a.75.75 0 0 1 .75-.75Z"
      :fill="color || 'currentColor'"
    />
  </svg>
</template>
