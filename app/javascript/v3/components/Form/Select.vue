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
    placeholder: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      required: true,
    },
    modelValue: {
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
  emits: ['update:modelValue'],
  methods: {
    onInput(e) {
      this.$emit('update:modelValue', e.target.value);
    },
  },
};
</script>

<template>
  <WithLabel
    :label="label"
    :icon="icon"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <select
      :id="id"
      :selected="modelValue"
      :name="name"
      :class="{
        'text-n-slate-9': !modelValue,
        'text-n-slate-12': modelValue,
        'pl-9': icon,
      }"
      class="block w-full px-3 py-2 pr-6 mb-0 border-0 shadow-sm appearance-none rounded-xl select-caret leading-6"
      @input="onInput"
    >
      <option value="" disabled selected class="hidden">
        {{ placeholder }}
      </option>
      <slot>
        <option v-for="opt in options" :key="opt.value" :value="opt.value">
          {{ opt.label }}
        </option>
      </slot>
    </select>
  </WithLabel>
</template>

<style scoped>
.select-caret {
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='32' height='24' viewBox='0 0 32 24'><polygon points='0,0 32,0 16,24' style='fill: rgb%28110, 111, 115%29'></polygon></svg>");
  background-origin: content-box;
  background-position: right -1rem center;
  background-repeat: no-repeat;
  background-size: 9px 6px;
}
</style>
