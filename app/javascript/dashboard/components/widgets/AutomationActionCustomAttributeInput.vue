<script>
import { useMapGetter } from 'dashboard/composables/store';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import InsertVariableButton from 'dashboard/components-next/variable/InsertVariableButton.vue';

export default {
  components: {
    NextInput,
    NextButton,
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

      return (source || [])
        .filter(attr => !attr.formula && !attr.attributeFormula)
        .map(attr => {
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
              attr.values ||
              attr.attributeValues ||
              attr.attribute_values ||
              [],
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
        const value = this.payload.value;
        return value === undefined || value === null ? '' : value;
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
    isNumberAttribute() {
      return ['number', 'currency', 'percent'].includes(
        this.selectedAttribute?.displayType
      );
    },
    isListAttribute() {
      return this.selectedAttribute?.displayType === 'list';
    },
    isCheckboxAttribute() {
      return this.selectedAttribute?.displayType === 'checkbox';
    },
    valueUsesLiquid() {
      return String(this.selectedValue || '').includes('{{');
    },
    inputType() {
      // Never use native date inputs here: they reject Liquid tokens like
      // {{ date.today }} and wipe the value before save validation.
      if (this.isNumberAttribute && !this.valueUsesLiquid) return 'number';
      return 'text';
    },
    valuePlaceholder() {
      if (this.isDateAttribute) {
        return this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PLACEHOLDER');
      }
      if (this.isNumberAttribute) {
        return this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_NUMBER_PLACEHOLDER');
      }
      return this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER');
    },
    showVariablePicker() {
      return (
        this.selectedKey && !this.isListAttribute && !this.isCheckboxAttribute
      );
    },
    selectClass() {
      // Override global `select` styles (custom SVG arrow + bg-origin-content)
      // which collide with native OS arrows and look broken at h-8.
      return [
        'block w-full reset-base appearance-none text-sm !mb-0 h-8',
        'pl-3 pr-9 py-1.5 border-none outline outline-1 outline-offset-[-1px] rounded-lg',
        'bg-n-alpha-black2 !bg-none text-n-slate-12',
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
      let nextValue = value ?? '';
      if (
        this.isNumberAttribute &&
        nextValue !== '' &&
        !String(nextValue).includes('{{')
      ) {
        const asNumber = Number(nextValue);
        nextValue = Number.isFinite(asNumber) ? asNumber : nextValue;
      }
      this.$emit('update:modelValue', {
        attribute_key: attributeKey || '',
        value: nextValue,
      });
    },
    insertVariable(token) {
      const current = this.selectedValue || '';
      this.selectedValue = current ? `${current}${token}` : token;
    },
    useToday() {
      this.selectedValue = '{{ date.today }}';
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
      <div class="relative">
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
        <span
          class="pointer-events-none absolute inset-y-0 right-2.5 flex items-center text-n-slate-11"
        >
          <span class="i-lucide-chevron-down size-3.5" />
        </span>
      </div>
      <p v-if="!attributeOptions.length" class="text-xs text-n-ruby-11 m-0">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_EMPTY') }}
      </p>
    </div>

    <div v-if="selectedKey" class="flex flex-col gap-1.5">
      <label class="text-sm font-medium text-n-slate-12">
        {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_LABEL') }}
      </label>

      <div v-if="isListAttribute" class="relative">
        <select v-model="selectedValue" :class="selectClass">
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
        <span
          class="pointer-events-none absolute inset-y-0 right-2.5 flex items-center text-n-slate-11"
        >
          <span class="i-lucide-chevron-down size-3.5" />
        </span>
      </div>

      <div v-else-if="isCheckboxAttribute" class="relative">
        <select v-model="selectedValue" :class="selectClass">
          <option value="true">
            {{ $t('FILTER.ATTRIBUTE_LABELS.TRUE') }}
          </option>
          <option value="false">
            {{ $t('FILTER.ATTRIBUTE_LABELS.FALSE') }}
          </option>
        </select>
        <span
          class="pointer-events-none absolute inset-y-0 right-2.5 flex items-center text-n-slate-11"
        >
          <span class="i-lucide-chevron-down size-3.5" />
        </span>
      </div>

      <template v-else>
        <NextInput
          v-model="selectedValue"
          :type="inputType"
          size="sm"
          :placeholder="valuePlaceholder"
        />
        <div
          v-if="showVariablePicker"
          class="flex items-center justify-between gap-2"
        >
          <NextButton
            v-if="isDateAttribute"
            xs
            faded
            slate
            :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_USE_TODAY')"
            @click="useToday"
          />
          <span v-else />
          <InsertVariableButton @insert="insertVariable" />
        </div>
      </template>
    </div>
  </div>
</template>
