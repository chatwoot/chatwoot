<template>
  <with-label
    :label="label"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <div class="flex gap-2 flex-wrap">
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
  </with-label>
</template>

<script>
import WithLabel from './WithLabel.vue';
export default {
  components: {
    WithLabel,
  },
  props: {
    id: {
      type: String,
      default: '',
    },
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
