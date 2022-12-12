<template>
  <a
    v-if="context.repeatable"
    :class="context.classes.groupRepeatableRemove"
    :data-disabled="context.model.length <= context.minimum"
    role="button"
    @click.prevent="removeItem"
    @keypress.enter="removeItem"
    v-text="context.removeLabel"
  />
</template>

<script>
export default {
  props: {
    index: {
      type: Number,
      default: null
    },
    context: {
      type: Object,
      required: true
    },
    removeItem: {
      type: Function,
      required: true
    }
  }
}
</script>
