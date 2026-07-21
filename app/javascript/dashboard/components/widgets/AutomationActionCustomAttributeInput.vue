<script>
export default {
  props: {
    attributes: { type: Array, default: () => [] },
    modelValue: { type: [Object, Array], default: () => ({}) },
  },
  emits: ['update:modelValue'],
  computed: {
    attributeOptions() {
      return (this.attributes || []).map(attr => ({
        id: attr.id,
        name: attr.name,
        displayType: attr.displayType || attr.display_type || 'text',
      }));
    },
    selectedKey: {
      get() {
        const data = Array.isArray(this.modelValue)
          ? this.modelValue[0] || {}
          : this.modelValue || {};
        return data.attribute_key || '';
      },
      set(attributeKey) {
        this.emitValue(attributeKey, this.selectedValue);
      },
    },
    selectedValue: {
      get() {
        const data = Array.isArray(this.modelValue)
          ? this.modelValue[0] || {}
          : this.modelValue || {};
        return data.value ?? '';
      },
      set(value) {
        this.emitValue(this.selectedKey, value);
      },
    },
    isDateAttribute() {
      const selected = this.attributeOptions.find(
        item => item.id === this.selectedKey
      );
      return selected?.displayType === 'date';
    },
  },
  methods: {
    emitValue(attributeKey, value) {
      this.$emit('update:modelValue', {
        attribute_key: attributeKey || '',
        value: value ?? '',
      });
    },
    insertToday() {
      this.selectedValue = '{{date.today}}';
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col gap-2 w-full mt-1 p-3 rounded-lg bg-n-alpha-1 outline outline-1 outline-n-weak"
  >
    <label class="text-xs font-medium text-n-slate-12">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_LABEL') }}
    </label>
    <select
      v-model="selectedKey"
      class="w-full mb-0 text-sm rounded-lg border-0 bg-n-solid-1 text-n-slate-12 px-3 py-2 outline outline-1 outline-n-weak"
    >
      <option disabled value="">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_SELECT_PLACEHOLDER') }}
      </option>
      <option v-for="attr in attributeOptions" :key="attr.id" :value="attr.id">
        {{ attr.name }}
      </option>
    </select>
    <p v-if="!attributeOptions.length" class="text-xs text-n-ruby-11 m-0">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_EMPTY') }}
    </p>

    <label class="text-xs font-medium text-n-slate-12">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_LABEL') }}
    </label>
    <input
      v-model="selectedValue"
      type="text"
      class="w-full mb-0 text-sm rounded-lg border-0 bg-n-solid-1 text-n-slate-12 px-3 py-2 outline outline-1 outline-n-weak"
      :placeholder="
        isDateAttribute
          ? $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PLACEHOLDER')
          : $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
      "
    />
    <div class="flex items-center justify-between gap-2">
      <span class="text-xs text-n-slate-11">
        {{ $t('AUTOMATION.ACTION.VARIABLES_HINT') }}
      </span>
      <button
        v-if="isDateAttribute"
        type="button"
        class="text-xs text-n-brand underline"
        @click="insertToday"
      >
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_USE_TODAY') }}
      </button>
    </div>
  </div>
</template>
