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
    <input
      v-model="context.model"
      :type="type"
      v-bind="attributes"
      v-on="$listeners"
      @blur="context.blurHandler"
    >
    <div
      v-if="context.showValue"
      :class="context.classes.rangeValue"
      v-text="context.model"
    />
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
  name: 'FormulateInputSlider',
  mixins: [FormulateInputMixin]
}
</script>
