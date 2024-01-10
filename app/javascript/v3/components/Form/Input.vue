<template>
  <div>
    <label
      v-if="label"
      :for="name"
      class="flex justify-between text-sm font-medium leading-6 text-slate-900 dark:text-white"
      :class="{ 'text-red-500': hasError }"
    >
      {{ label }}
      <slot />
    </label>
    <div class="mt-1">
      <input
        :id="name"
        :name="name"
        :type="type"
        autocomplete="off"
        :required="required"
        :placeholder="placeholder"
        :data-testid="dataTestid"
        :value="value"
        :class="{
          'focus:ring-red-600 ring-red-600': hasError,
          'dark:ring-slate-600 dark:focus:ring-woot-500 ring-slate-200':
            !hasError,
        }"
        class="block w-full rounded-md border-0 px-3 py-3 appearance-none shadow-sm ring-1 ring-inset text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-woot-500 sm:text-sm sm:leading-6 outline-none dark:bg-slate-700"
        @input="onInput"
        @blur="$emit('blur')"
      />
      <span
        v-if="errorMessage && hasError"
        class="text-xs leading-2 text-red-400"
      >
        {{ errorMessage }}
      </span>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      default: 'text',
    },
    required: {
      type: Boolean,
      default: false,
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: [String, Number],
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
    dataTestid: {
      type: String,
      default: '',
    },
  },
  methods: {
    onInput(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
