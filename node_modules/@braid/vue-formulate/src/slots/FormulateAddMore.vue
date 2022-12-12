<template>
  <div :class="context.classes.groupAddMore">
    <FormulateInput
      type="button"
      :label="context.addLabel"
      data-minor
      data-ghost
      @click="addMore"
    />
  </div>
</template>

<script>
export default {
  props: {
    context: {
      type: Object,
      required: true
    },
    addMore: {
      type: Function,
      required: true
    }
  }
}
</script>
