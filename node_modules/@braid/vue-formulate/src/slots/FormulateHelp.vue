<template>
  <div
    v-if="context.help"
    :id="`${context.id}-help`"
    :class="context.classes.help"
    v-text="context.help"
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
