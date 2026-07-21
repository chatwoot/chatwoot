<script>
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import InsertVariableButton from 'dashboard/components-next/variable/InsertVariableButton.vue';

export default {
  components: {
    SingleSelect,
    NextInput,
    InsertVariableButton,
  },
  props: {
    attributes: { type: Array, default: () => [] },
    modelValue: { type: [Object, Array], default: () => ({}) },
    dropdownMaxHeight: { type: String, default: 'max-h-80' },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      selectedAttribute: null,
      value: '',
    };
  },
  computed: {
    attributeOptions() {
      return (this.attributes || []).map(attr => ({
        id: attr.id,
        name: attr.name,
        displayType: attr.displayType || attr.display_type || 'text',
      }));
    },
    isDateAttribute() {
      return this.selectedAttribute?.displayType === 'date';
    },
  },
  watch: {
    modelValue: {
      immediate: true,
      deep: true,
      handler(val) {
        const data = Array.isArray(val) ? val[0] || {} : val || {};
        const key = data.attribute_key;
        this.selectedAttribute =
          this.attributeOptions.find(item => item.id === key) || null;
        this.value = data.value ?? '';
      },
    },
    attributes: {
      immediate: true,
      handler() {
        const data = Array.isArray(this.modelValue)
          ? this.modelValue[0] || {}
          : this.modelValue || {};
        const key = data.attribute_key;
        if (key) {
          this.selectedAttribute =
            this.attributeOptions.find(item => item.id === key) || null;
        }
      },
    },
  },
  methods: {
    onAttributeChange(option) {
      this.selectedAttribute = option?.id ? option : null;
      this.value = '';
      this.emitValue();
    },
    insertVariable(token) {
      this.value = this.value ? `${this.value}${token}` : token;
      this.emitValue();
    },
    onValueInput(val) {
      this.value = val ?? '';
      this.emitValue();
    },
    emitValue() {
      this.$emit('update:modelValue', {
        attribute_key: this.selectedAttribute?.id || '',
        value: this.value,
      });
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col gap-2 w-full p-2 rounded-lg bg-n-alpha-1 outline outline-1 outline-n-weak"
  >
    <label class="text-xs font-medium text-n-slate-11">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_LABEL') }}
    </label>
    <SingleSelect
      :model-value="selectedAttribute"
      :options="attributeOptions"
      :placeholder="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_SELECT_PLACEHOLDER')"
      :dropdown-max-height="dropdownMaxHeight"
      disable-deselect
      class="w-full"
      @update:model-value="onAttributeChange"
    />
    <p v-if="!attributeOptions.length" class="text-xs text-n-ruby-11">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_EMPTY') }}
    </p>
    <label class="text-xs font-medium text-n-slate-11">
      {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_LABEL') }}
    </label>
    <NextInput
      :model-value="value"
      type="text"
      size="sm"
      class="w-full"
      :placeholder="
        isDateAttribute
          ? $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PLACEHOLDER')
          : $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
      "
      @update:model-value="onValueInput"
    />
    <div class="flex items-center justify-between gap-2">
      <span class="text-xs text-n-slate-11">
        {{ $t('AUTOMATION.ACTION.VARIABLES_HINT') }}
      </span>
      <InsertVariableButton @insert="insertVariable" />
    </div>
  </div>
</template>
