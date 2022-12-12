<template>
  <ul
    v-if="visibleErrors.length"
    :class="outerClass"
  >
    <li
      v-for="error in visibleErrors"
      :key="error"
      :class="itemClass"
      :role="role"
      :aria-live="ariaLive"
      v-text="error"
    />
  </ul>
</template>

<script>
export default {
  props: {
    visibleErrors: {
      type: Array,
      required: true
    },
    itemClass: {
      type: [String, Array, Object, Boolean],
      default: false
    },
    outerClass: {
      type: [String, Array, Object, Boolean],
      default: false
    },
    role: {
      type: [String],
      default: 'status'
    },
    ariaLive: {
      type: [String, Boolean],
      default: 'polite'
    },
    type: {
      type: String,
      required: true
    }
  }
}
</script>
