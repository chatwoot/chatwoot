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
      handler(val) {
        const data = Array.isArray(val) ? val[0] : val;
        const key = data?.attribute_key;
        this.selectedAttribute =
          this.attributeOptions.find(item => item.id === key) || null;
        this.value = data?.value ?? '';
      },
    },
  },
  methods: {
    onAttributeChange(option) {
      this.selectedAttribute = option;
      this.value = '';
      this.emitValue();
    },
    insertVariable(token) {
      this.value = this.value ? `${this.value} ${token}` : token;
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
  <div class="flex flex-col gap-2">
    <SingleSelect
      :model-value="selectedAttribute"
      :options="attributeOptions"
      :dropdown-max-height="dropdownMaxHeight"
      disable-deselect
      @update:model-value="onAttributeChange"
    />
    <div class="flex flex-col gap-1">
      <NextInput
        v-model="value"
        type="text"
        size="sm"
        :placeholder="
          isDateAttribute
            ? $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PLACEHOLDER')
            : $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
        "
        @update:model-value="emitValue"
      />
      <div class="flex items-center justify-between gap-2">
        <span class="text-xs text-n-slate-11">
          {{ $t('AUTOMATION.ACTION.VARIABLES_HINT') }}
        </span>
        <InsertVariableButton @insert="insertVariable" />
      </div>
    </div>
  </div>
</template>
