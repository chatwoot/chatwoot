<template>
  <div
    :class="context.classes.element"
    :data-type="context.type"
  >
    <FormulateSlot
      name="prefix"
      :context="context"
    >
      <component
        :is="context.slotComponents.prefix"
        v-if="context.slotComponents.prefix"
        :context="context"
      />
    </FormulateSlot>
    <button
      :type="type"
      v-bind="attributes"
      v-on="$listeners"
    >
      <slot :context="context">
        <component
          :is="context.slotComponents.buttonContent"
          :context="context"
        />
      </slot>
    </button>
    <FormulateSlot
      name="suffix"
      :context="context"
    >
      <component
        :is="context.slotComponents.suffix"
        v-if="context.slotComponents.suffix"
        :context="context"
      />
    </FormulateSlot>
  </div>
</template>

<script>
import FormulateInputMixin from '../FormulateInputMixin'

export default {
  name: 'FormulateInputButton',
  mixins: [FormulateInputMixin]
}
</script>
