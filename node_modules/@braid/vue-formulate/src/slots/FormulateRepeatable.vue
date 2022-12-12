<template>
  <div
    :class="context.classes.groupRepeatable"
  >
    <slot v-if="context.removePosition === 'after'" />
    <FormulateSlot
      name="remove"
      :context="context"
      :index="index"
      :remove-item="removeItem"
    >
      <component
        :is="context.slotComponents.remove"
        :context="context"
        :index="index"
        :remove-item="removeItem"
        v-bind="context.slotProps.remove"
      />
    </FormulateSlot>
    <slot v-if="context.removePosition === 'before'" />
  </div>
</template>

<script>
export default {
  props: {
    context: {
      type: Object,
      required: true
    },
    removeItem: {
      type: Function,
      required: true
    },
    index: {
      type: Number,
      required: true
    }
  }
}
</script>
