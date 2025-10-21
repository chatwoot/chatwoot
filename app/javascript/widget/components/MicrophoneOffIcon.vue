<script>
export default {
  name: 'MicrophoneOffIcon',
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
      d="M3.28 2.22a.75.75 0 1 0-1.06 1.06L8 9.06V12a4 4 0 0 0 6.248 3.309l1.146 1.146A5.227 5.227 0 0 1 12.25 17.5h-.5l-.216-.004A5.25 5.25 0 0 1 6.5 12.25v-.5l-.007-.102A.75.75 0 0 0 5 11.75v.5l.004.236a6.75 6.75 0 0 0 6.246 6.496v2.268l.007.102a.75.75 0 0 0 1.493-.102l.001-2.268a6.718 6.718 0 0 0 3.712-1.458l4.256 4.256a.75.75 0 0 0 1.061-1.06L3.28 2.22ZM17.196 14.014l1.146 1.146A6.725 6.725 0 0 0 19 12.25v-.5l-.007-.102a.75.75 0 0 0-1.493.102v.5l-.004.216a5.233 5.233 0 0 1-.3 1.548ZM8.138 4.956l7.792 7.792c.046-.242.07-.492.07-.748V6a4 4 0 0 0-7.862-1.044Z"
      :fill="color || 'currentColor'"
    />
  </svg>
</template>
