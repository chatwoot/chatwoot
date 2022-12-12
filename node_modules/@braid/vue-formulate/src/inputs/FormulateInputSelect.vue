<template>
  <div
    :class="context.classes.element"
    :data-type="context.type"
    :data-multiple="attributes && attributes.multiple !== undefined"
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
    <select
      v-model="context.model"
      v-bind="attributes"
      :data-placeholder-selected="placeholderSelected"
      v-on="$listeners"
      @blur="context.blurHandler"
    >
      <option
        v-if="context.placeholder"
        value
        hidden="hidden"
        disabled
        :selected="!hasValue"
      >
        {{ context.placeholder }}
      </option>
      <template
        v-if="!optionGroups"
      >
        <option
          v-for="option in options"
          :key="option.id"
          :value="option.value"
          :disabled="!!option.disabled"
          v-bind="option.attributes || option.attrs || {}"
          v-text="option.label"
        />
      </template>
      <template
        v-else
      >
        <optgroup
          v-for="(subOptions, label) in optionGroups"
          :key="label"
          :label="label"
        >
          <option
            v-for="option in subOptions"
            :key="option.id"
            :value="option.value"
            :disabled="!!option.disabled"
            v-bind="option.attributes || option.attrs || {}"
            v-text="option.label"
          />
        </optgroup>
      </template>
    </select>
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
  name: 'FormulateInputSelect',
  mixins: [FormulateInputMixin],
  computed: {
    options () {
      return this.context.options || {}
    },
    optionGroups () {
      return this.context.optionGroups || false
    },
    placeholderSelected () {
      return !!(!this.hasValue && this.context.attributes && this.context.attributes.placeholder)
    }
  }
}
</script>
