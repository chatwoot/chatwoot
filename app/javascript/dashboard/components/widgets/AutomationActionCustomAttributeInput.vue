<script>
import { useMapGetter } from 'dashboard/composables/store';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import InsertVariableButton from 'dashboard/components-next/variable/InsertVariableButton.vue';

const DAY_PRESETS = [7, 15, 30];
const MAX_RELATIVE_DAYS = 365;

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
  data() {
    return {
      // Switch away from native date/datetime inputs BEFORE writing Liquid,
      // otherwise the browser rejects `{{ ... }}` and emits '' (clears the action).
      preferLiquidMode: false,
      dayPresets: DAY_PRESETS,
    };
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
        this.preferLiquidMode = false;
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
    isDatetimeAttribute() {
      return this.selectedAttribute?.displayType === 'datetime';
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
      return (
        this.preferLiquidMode || String(this.selectedValue || '').includes('{{')
      );
    },
    relativeParsed() {
      return this.parseRelativeLiquid(this.selectedValue);
    },
    isRelativeLiquid() {
      return this.relativeParsed.base != null;
    },
    relativeDays() {
      return this.relativeParsed.days;
    },
    relativeBase() {
      if (this.isDatetimeAttribute) return 'now';
      return 'today';
    },
    relativeSummary() {
      const days = this.relativeDays;
      if (this.isDatetimeAttribute) {
        return days === 0
          ? this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATETIME_DYNAMIC_NOW')
          : this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_NOW_PLUS', {
              n: days,
            });
      }
      return days === 0
        ? this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_DYNAMIC_TODAY')
        : this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_TODAY_PLUS', {
            n: days,
          });
    },
    inputType() {
      // Fixed dates use the native picker (ISO YYYY-MM-DD only).
      // Relative dates use Liquid and leave the native picker.
      if (this.isDateAttribute && !this.valueUsesLiquid) return 'date';
      if (this.isDatetimeAttribute && !this.valueUsesLiquid) {
        return 'datetime-local';
      }
      if (this.isNumberAttribute && !this.valueUsesLiquid) return 'number';
      return 'text';
    },
    valuePlaceholder() {
      if (this.isNumberAttribute) {
        return this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_NUMBER_PLACEHOLDER');
      }
      return this.$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_VALUE_PLACEHOLDER');
    },
    showVariablePicker() {
      if (this.isDateAttribute) return false;
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
  watch: {
    modelValue: {
      immediate: true,
      handler() {
        if (String(this.payload.value || '').includes('{{')) {
          this.preferLiquidMode = true;
        }
      },
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
        8: 'datetime',
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
    applyLiquidValue(token) {
      this.preferLiquidMode = true;
      this.$nextTick(() => {
        this.selectedValue = token;
      });
    },
    insertVariable(token) {
      this.preferLiquidMode = true;
      this.$nextTick(() => {
        const current = String(this.selectedValue || '');
        const isFixedDate =
          /^\d{4}-\d{2}-\d{2}/.test(current) && !current.includes('{{');
        this.selectedValue =
          !current || isFixedDate ? token : `${current}${token}`;
      });
    },
    buildRelativeLiquid(base, days) {
      const n = Math.min(
        MAX_RELATIVE_DAYS,
        Math.max(0, Number.parseInt(days, 10) || 0)
      );
      if (n === 0) return `{{ date.${base} }}`;
      return `{{ date.${base} | plus_days: ${n} }}`;
    },
    parseRelativeLiquid(value) {
      const text = String(value || '').trim();
      let match = text.match(/^\{\{\s*date\.(today|now)\s*\}\}$/);
      if (match) return { base: match[1], days: 0 };

      match = text.match(
        /^\{\{\s*date\.(today|now)\s*\|\s*plus_days:\s*(\d+)\s*\}\}$/
      );
      if (match) {
        return {
          base: match[1],
          days: Math.min(MAX_RELATIVE_DAYS, Number(match[2])),
        };
      }
      return { base: null, days: 0 };
    },
    applyRelativeDays(days) {
      this.applyLiquidValue(this.buildRelativeLiquid(this.relativeBase, days));
    },
    onRelativeDaysInput(raw) {
      const n = Math.min(
        MAX_RELATIVE_DAYS,
        Math.max(0, Number.parseInt(raw, 10) || 0)
      );
      this.applyRelativeDays(n);
    },
    useToday() {
      this.applyRelativeDays(0);
    },
    useNow() {
      this.applyLiquidValue(this.buildRelativeLiquid('now', 0));
    },
    useFixedDate() {
      this.preferLiquidMode = false;
      this.selectedValue = '';
    },
    presetChipClass(days) {
      const active = this.isRelativeLiquid && this.relativeDays === days;
      return [
        'inline-flex items-center justify-center h-7 px-2.5 rounded-lg text-xs font-medium',
        'outline outline-1 outline-offset-[-1px] transition-colors',
        active
          ? 'bg-n-brand/15 text-n-brand outline-n-brand'
          : 'bg-n-alpha-black2 text-n-slate-12 outline-n-weak hover:outline-n-slate-6',
      ].join(' ');
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

      <template
        v-else-if="isDateAttribute && valueUsesLiquid && isRelativeLiquid"
      >
        <div
          class="flex flex-col gap-2 rounded-lg bg-n-alpha-black2 px-3 py-2 outline outline-1 outline-n-weak"
        >
          <p class="text-sm text-n-slate-12 m-0">
            {{ relativeSummary }}
          </p>
          <p class="text-xs text-n-slate-11 m-0 font-mono">
            {{ selectedValue }}
          </p>
          <p class="text-xs text-n-slate-11 m-0">
            {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_DYNAMIC_HELP') }}
          </p>
          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              :class="presetChipClass(0)"
              @click="applyRelativeDays(0)"
            >
              {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_TODAY_CHIP') }}
            </button>
            <button
              v-for="days in dayPresets"
              :key="`date-preset-${days}`"
              type="button"
              :class="presetChipClass(days)"
              @click="applyRelativeDays(days)"
            >
              +{{ days }}
            </button>
            <label
              class="inline-flex items-center gap-1.5 text-xs text-n-slate-11"
            >
              <span>{{
                $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_DAYS_LABEL')
              }}</span>
              <input
                class="w-16 h-7 px-2 rounded-lg text-xs text-n-slate-12 bg-n-solid-2 outline outline-1 outline-n-weak focus:outline-n-brand"
                type="number"
                min="0"
                :max="365"
                :value="relativeDays"
                @change="onRelativeDaysInput($event.target.value)"
              />
            </label>
          </div>
          <div class="flex items-center gap-2">
            <NextButton
              xs
              faded
              slate
              :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PICK_FIXED')"
              @click="useFixedDate"
            />
          </div>
        </div>
      </template>

      <template v-else-if="isDateAttribute && valueUsesLiquid">
        <NextInput
          v-model="selectedValue"
          type="text"
          size="sm"
          :placeholder="valuePlaceholder"
        />
        <p class="text-xs text-n-slate-11 m-0">
          {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_DYNAMIC_HELP') }}
        </p>
        <div class="flex items-center gap-2 flex-wrap">
          <NextButton
            xs
            faded
            slate
            :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PICK_FIXED')"
            @click="useFixedDate"
          />
          <NextButton
            xs
            faded
            slate
            :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_USE_TODAY')"
            @click="useToday"
          />
        </div>
      </template>

      <template v-else-if="isDateAttribute">
        <NextInput v-model="selectedValue" type="date" size="sm" />
        <div class="flex flex-wrap items-center gap-2">
          <NextButton
            xs
            faded
            slate
            :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_USE_TODAY')"
            @click="useToday"
          />
          <button
            v-for="days in dayPresets"
            :key="`date-fixed-preset-${days}`"
            type="button"
            :class="presetChipClass(days)"
            @click="applyRelativeDays(days)"
          >
            +{{ days }}
          </button>
        </div>
      </template>

      <template
        v-else-if="isDatetimeAttribute && valueUsesLiquid && isRelativeLiquid"
      >
        <div
          class="flex flex-col gap-2 rounded-lg bg-n-alpha-black2 px-3 py-2 outline outline-1 outline-n-weak"
        >
          <p class="text-sm text-n-slate-12 m-0">
            {{ relativeSummary }}
          </p>
          <p class="text-xs text-n-slate-11 m-0 font-mono">
            {{ selectedValue }}
          </p>
          <p class="text-xs text-n-slate-11 m-0">
            {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATETIME_DYNAMIC_HELP') }}
          </p>
          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              :class="presetChipClass(0)"
              @click="applyRelativeDays(0)"
            >
              {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_NOW_CHIP') }}
            </button>
            <button
              v-for="days in dayPresets"
              :key="`datetime-preset-${days}`"
              type="button"
              :class="presetChipClass(days)"
              @click="applyRelativeDays(days)"
            >
              +{{ days }}
            </button>
            <label
              class="inline-flex items-center gap-1.5 text-xs text-n-slate-11"
            >
              <span>{{
                $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_RELATIVE_DAYS_LABEL')
              }}</span>
              <input
                class="w-16 h-7 px-2 rounded-lg text-xs text-n-slate-12 bg-n-solid-2 outline outline-1 outline-n-weak focus:outline-n-brand"
                type="number"
                min="0"
                :max="365"
                :value="relativeDays"
                @change="onRelativeDaysInput($event.target.value)"
              />
            </label>
          </div>
          <div class="flex items-center justify-between gap-2 flex-wrap">
            <NextButton
              xs
              faded
              slate
              :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PICK_FIXED')"
              @click="useFixedDate"
            />
            <InsertVariableButton @insert="insertVariable" />
          </div>
        </div>
      </template>

      <template v-else-if="isDatetimeAttribute && valueUsesLiquid">
        <NextInput
          v-model="selectedValue"
          type="text"
          size="sm"
          :placeholder="valuePlaceholder"
        />
        <p class="text-xs text-n-slate-11 m-0">
          {{ $t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATETIME_DYNAMIC_HELP') }}
        </p>
        <div class="flex items-center justify-between gap-2 flex-wrap">
          <NextButton
            xs
            faded
            slate
            :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_DATE_PICK_FIXED')"
            @click="useFixedDate"
          />
          <InsertVariableButton @insert="insertVariable" />
        </div>
      </template>

      <template v-else-if="isDatetimeAttribute">
        <NextInput v-model="selectedValue" type="datetime-local" size="sm" />
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div class="flex flex-wrap items-center gap-2">
            <NextButton
              xs
              faded
              slate
              :label="$t('AUTOMATION.ACTION.CUSTOM_ATTRIBUTE_USE_NOW')"
              @click="useNow"
            />
            <button
              v-for="days in dayPresets"
              :key="`datetime-fixed-preset-${days}`"
              type="button"
              :class="presetChipClass(days)"
              @click="applyRelativeDays(days)"
            >
              +{{ days }}
            </button>
          </div>
          <InsertVariableButton @insert="insertVariable" />
        </div>
      </template>

      <template v-else>
        <NextInput
          v-model="selectedValue"
          :type="inputType"
          size="sm"
          :placeholder="valuePlaceholder"
        />
        <div
          v-if="showVariablePicker"
          class="flex items-center justify-end gap-2"
        >
          <InsertVariableButton @insert="insertVariable" />
        </div>
      </template>
    </div>
  </div>
</template>
