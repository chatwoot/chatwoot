<script>
import { useMapGetter } from 'dashboard/composables/store';
import NextInput from 'dashboard/components-next/input/Input.vue';
import InsertVariableButton from 'dashboard/components-next/variable/InsertVariableButton.vue';

export default {
  components: {
    NextInput,
    InsertVariableButton,
  },
  props: {
    attributes: { type: Array, default: () => [] },
    modelValue: { type: [Object, Array], default: () => ({}) },
    attributeModel: {
      type: String,
      default: 'contact_attribute',
      validator: value =>
        ['contact_attribute', 'conversation_attribute'].includes(value),
    },
  },
  emits: ['update:modelValue'],
  setup() {
    const contactAttributes = useMapGetter('attributes/getContactAttributes');
    const conversationAttributes = useMapGetter(
      'attributes/getConversationAttributes'
    );
    return { contactAttributes, conversationAttributes };
  },
  computed: {
    storeAttributes() {
      if (this.attributeModel === 'conversation_attribute') {
        return this.conversationAttributes || [];
      }
      return this.contactAttributes || [];
    },
    attributeOptions() {
      const source =
        this.attributes?.length > 0 ? this.attributes : this.storeAttributes;

      return (source || []).map(attr => {
        const displayType = this.normalizeDisplayType(attr);
        return {
          id: attr.attributeKey || attr.attribute_key || attr.id,
          name:
            attr.name ||
            attr.attributeDisplayName ||
            attr.attribute_display_name ||
            attr.attributeKey ||
            attr.attribute_key,
          displayType,
          values:
            attr.values || attr.attributeValues || attr.attribute_values || [],
        };
      });
    },
    selectedKey: {
      get() {
        return this.payload.attribute_key || '';
      },
      set(attributeKey) {
        this.emitValue(attributeKey, '');
      },
    },
    selectedValue: {
      get() {
        return this.payload.value ?? '';
      },
      set(value) {
        this.emitValue(this.selectedKey, value);
      },
    },
    payload() {
      const data = Array.isArray(this.modelValue)
        ? this.modelValue[0] || {}
        : this.modelValue || {};
      return data;
    },
    selectedAttribute() {
      return this.attributeOptions.find(item => item.id === this.selectedKey);
    },
    isDateAttribute() {
      return this.selectedAttribute?.displayType === 'date';
    },
    isListAttribute() {
      return this.selectedAttribute?.displayType === 'list';
    },
    isCheckboxAttribute() {
      return this.selectedAttribute?.displayType === 'checkbox';
    },
    showVariablePicker() {
      return (
        this.selectedKey && !this.isListAttribute && !this.isCheckboxAttribute
      );
    },
    selectClass() {
      return [
        'block w-full reset-base text-sm !mb-0 h-8 px-3 py-2',
        'outline outline-1 border-none outline-offset-[-1px] rounded-lg',
        'bg-n-alpha-black2 text-n-slate-12',
        'outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand',
      ].join(' ');
    },
  },
  methods: {
    normalizeDisplayType(attr) {
      const map = {
        0: 'text',
        1: 'number',
        2: 'currency',
        3: 'percent',
        4: 'link',
        5: 'date',
        6: 'list',
        7: 'checkbox',
      };
      const raw =
        attr.displayType ??
        attr.attributeDisplayType ??
        attr.attribute_display_type ??
        'text';
      if (typeof raw === 'number') return map[raw] || 'text';
      return String(raw);
    },
    emitValue(attributeKey, value) {
      this.$emit('update:modelValue', {
        attribute_key: attributeKey || '',
        value: value ?? '',
      });
    },
    insertVariable(token) {
      const current = this.selectedValue || '';
      this.selectedValue = current ? `${current}${token}` : token;
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col gap-3 w-full mt-1 p-3 rounded-lg bg-n-solid-2 outline outline-1 outline-n-weak"
  >
    <div class="flex flex-col gap-1.5">
      <label class="text-sm font-medium text-n-slate-12">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_LABEL') }}
      </label>
      <select v-model="selectedKey" :class="selectClass">
        <option disabled value="">
          {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_SELECT_PLACEHOLDER') }}
        </option>
        <option
          v-for="attr in attributeOptions"
          :key="attr.id"
          :value="attr.id"
        >
          {{ attr.name }}
        </option>
      </select>
      <p v-if="!attributeOptions.length" class="text-xs text-n-ruby-11 m-0">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_EMPTY') }}
      </p>
    </div>

    <div v-if="selectedKey" class="flex flex-col gap-1.5">
      <label class="text-sm font-medium text-n-slate-12">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_LABEL') }}
      </label>

      <select
        v-if="isListAttribute"
        v-model="selectedValue"
        :class="selectClass"
      >
        <option disabled value="">
          {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_SELECT_PLACEHOLDER') }}
        </option>
        <option
          v-for="option in selectedAttribute?.values || []"
          :key="option"
          :value="option"
        >
          {{ option }}
        </option>
      </select>

      <select
        v-else-if="isCheckboxAttribute"
        v-model="selectedValue"
        :class="selectClass"
      >
        <option value="true">
          {{ $t('FILTER.ATTRIBUTE_LABELS.TRUE') }}
        </option>
        <option value="false">
          {{ $t('FILTER.ATTRIBUTE_LABELS.FALSE') }}
        </option>
      </select>

      <template v-else>
        <NextInput
          v-model="selectedValue"
          type="text"
          size="sm"
          :placeholder="
            isDateAttribute
              ? $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PLACEHOLDER')
              : $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER')
          "
        />
        <div v-if="showVariablePicker" class="flex items-center justify-end">
          <InsertVariableButton @insert="insertVariable" />
        </div>
      </template>
    </div>
  </div>
</template>
