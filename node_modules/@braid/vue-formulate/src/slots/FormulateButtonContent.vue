<template>
  <span
    :class="`formulate-input-element--${context.type}--label`"
    v-text="context.value || context.label || context.name || 'Submit'"
  />
</template>

<script>
export default {
  props: {
    context: {
      type: Object,
      required: true
    }
  }
}
</script>
