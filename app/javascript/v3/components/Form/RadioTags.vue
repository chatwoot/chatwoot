<script>
import WithLabel from './WithLabel.vue';
export default {
  components: {
    WithLabel,
  },
  props: {
    options: {
      type: Array,
      default: () => [],
    },
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <WithLabel
    :label="label"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <div class="flex flex-wrap gap-2">
      <woot-button
        v-for="option in options"
        :key="option.value"
        :variant="value === option.value ? '' : 'hollow'"
        :color-scheme="value === option.value ? 'primary' : 'secondary'"
        size="small"
        @click="$emit('input', option.value)"
      >
        {{ option.label }}
      </woot-button>
    </div>
  </WithLabel>
</template>
