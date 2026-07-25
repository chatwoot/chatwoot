<script>
import { format, parseISO } from 'date-fns';
import { required, url } from '@vuelidate/validators';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useToggle } from '@vueuse/core';
import { isValidURL } from '../helper/URLHelper';
import { getRegexp } from 'shared/helpers/Validators';
import { useVuelidate } from '@vuelidate/core';
import { emitter } from 'shared/helpers/mitt';

import NextButton from 'dashboard/components-next/button/Button.vue';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const DATE_FORMAT = 'yyyy-MM-dd';

const toDatetimeLocalValue = date => {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return '';
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

export default {
  components: {
    NextButton,
    OutlinedAttributeField,
    DropdownMenu,
  },
  props: {
    label: { type: String, required: true },
    description: { type: String, default: '' },
    values: { type: Array, default: () => [] },
    value: { type: [String, Number, Boolean, Array], default: '' },
    showActions: { type: Boolean, default: false },
    attributeType: { type: String, default: 'text' },
    attributeRegex: {
      type: String,
      default: null,
    },
    regexCue: { type: String, default: null },
    attributeKey: { type: String, required: true },
    contactId: { type: Number, default: null },
    readOnly: { type: Boolean, default: false },
  },
  emits: ['update', 'delete', 'copy'],
  setup() {
    const [showListDropdown, toggleListDropdown] = useToggle(false);
    return { v$: useVuelidate(), showListDropdown, toggleListDropdown };
  },
  data() {
    return {
      isEditing: false,
      editedValue: null,
      isFocused: false,
      currencyPrefix: '$',
      percentSuffix: '%',
      emptyListPlaceholder: '—',
    };
  },
  computed: {
    isAttributeTypeCheckbox() {
      return this.attributeType === 'checkbox';
    },
    isAttributeTypeList() {
      return this.attributeType === 'list';
    },
    isAttributeTypeMultiList() {
      return this.attributeType === 'multi_list';
    },
    isAttributeTypeLink() {
      return this.attributeType === 'link';
    },
    isAttributeTypeDate() {
      return this.attributeType === 'date';
    },
    isAttributeTypeDatetime() {
      return this.attributeType === 'datetime';
    },
    isAttributeTypeCurrency() {
      return this.attributeType === 'currency';
    },
    isAttributeTypePercent() {
      return this.attributeType === 'percent';
    },
    hasValue() {
      if (this.isAttributeTypeMultiList) {
        return Array.isArray(this.value) && this.value.length > 0;
      }
      if (this.isAttributeTypeCheckbox) {
        return this.value === true || this.value === 'true';
      }
      return (
        this.value !== null && this.value !== undefined && this.value !== ''
      );
    },
    displayValue() {
      if (this.isAttributeTypeMultiList) {
        if (!Array.isArray(this.value) || !this.value.length) return '';
        return this.value.join(', ');
      }
      if (this.isAttributeTypeDatetime) {
        return this.value ? new Date(this.value).toLocaleString() : '';
      }
      if (this.isAttributeTypeDate) {
        return this.value ? new Date(this.value).toLocaleDateString() : '';
      }
      if (this.isAttributeTypeCurrency && this.hasValue) {
        return `$${this.value}`;
      }
      if (this.isAttributeTypePercent && this.hasValue) {
        return `${this.value}%`;
      }
      if (this.isAttributeTypeCheckbox) {
        return this.value === 'false' ? false : this.value;
      }
      return this.hasValue ? this.value : '';
    },
    formattedValue() {
      if (this.isAttributeTypeMultiList) {
        return Array.isArray(this.value) ? [...this.value] : [];
      }
      if (this.isAttributeTypeDatetime) {
        return this.value
          ? toDatetimeLocalValue(this.value)
          : toDatetimeLocalValue(new Date());
      }
      return this.isAttributeTypeDate
        ? format(this.value ? new Date(this.value) : new Date(), DATE_FORMAT)
        : this.value;
    },
    listMenuItems() {
      return (this.values || []).map(option => ({
        label: option,
        value: option,
        action: 'select',
        isSelected: option === this.value,
      }));
    },
    urlValue() {
      return isValidURL(this.value) ? this.value : '---';
    },
    hrefURL() {
      return isValidURL(this.value) ? this.value : '';
    },
    multiListSelected() {
      return Array.isArray(this.editedValue) ? this.editedValue : [];
    },
    inputType() {
      if (this.isAttributeTypeDatetime) return 'datetime-local';
      if (this.isAttributeTypeLink) return 'url';
      if (
        this.attributeType === 'number' ||
        this.isAttributeTypeCurrency ||
        this.isAttributeTypePercent
      ) {
        return 'number';
      }
      return this.isAttributeTypeDate ? 'date' : 'text';
    },
    shouldShowErrorMessage() {
      return this.v$.editedValue.$error;
    },
    errorMessage() {
      if (this.v$.editedValue.url?.$invalid) {
        return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_URL');
      }
      if (this.v$.editedValue.regexValidation?.$invalid) {
        return (
          this.regexCue ||
          this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_INPUT')
        );
      }
      return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.REQUIRED');
    },
    shellFilled() {
      return this.hasValue || this.isEditing || this.showListDropdown;
    },
    shellFocused() {
      return this.isFocused || this.isEditing || this.showListDropdown;
    },
  },
  watch: {
    value() {
      this.isEditing = false;
      this.editedValue = this.formattedValue;
    },
    contactId() {
      this.v$.$reset();
    },
  },

  validations() {
    if (this.isAttributeTypeLink) {
      return {
        editedValue: { required, url },
      };
    }
    return {
      editedValue: {
        required,
        regexValidation: value => {
          if (!this.attributeRegex || !value) return true;
          try {
            return getRegexp(this.attributeRegex).test(value);
          } catch {
            return false;
          }
        },
      },
    };
  },
  mounted() {
    this.editedValue = this.formattedValue;
    emitter.on(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
  },
  unmounted() {
    emitter.off(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
  },
  methods: {
    onFocusAttribute(focusAttributeKey) {
      if (this.attributeKey === focusAttributeKey && !this.readOnly) {
        this.onEdit();
      }
    },
    focusInput() {
      if (this.$refs.inputfield) {
        this.$refs.inputfield.focus();
      }
    },
    onClickAway() {
      this.v$.$reset();
      this.isEditing = false;
      this.isFocused = false;
    },
    onEdit() {
      if (!this.showActions || this.readOnly) return;
      this.isEditing = true;
      this.isFocused = true;
      this.$nextTick(() => {
        this.focusInput();
      });
    },
    openListDropdown() {
      if (this.readOnly) return;
      this.toggleListDropdown();
    },
    closeListDropdown() {
      this.toggleListDropdown(false);
    },
    onSelectListValue(item) {
      this.editedValue = item.value;
      this.closeListDropdown();
      this.onUpdate();
    },
    onToggleMultiListValue(optionName, checked) {
      if (this.readOnly) return;
      const current = Array.isArray(this.editedValue)
        ? [...this.editedValue]
        : [];
      if (checked) {
        if (!current.includes(optionName)) current.push(optionName);
      } else {
        const idx = current.indexOf(optionName);
        if (idx >= 0) current.splice(idx, 1);
      }
      this.editedValue = current;
      this.onUpdate();
    },
    onUpdate() {
      if (this.readOnly) return;
      let updatedValue =
        this.isAttributeTypeDate || this.isAttributeTypeDatetime
          ? parseISO(this.editedValue)
          : this.editedValue;
      if (this.isAttributeTypeCurrency) {
        const num = Number(updatedValue);
        if (Number.isNaN(num) || num < 0) {
          this.v$.$touch();
          return;
        }
        updatedValue = num;
      }
      if (!this.isAttributeTypeMultiList && !this.isAttributeTypeCheckbox) {
        this.v$.$touch();
        if (this.v$.$invalid) {
          return;
        }
      }
      this.isEditing = false;
      this.isFocused = false;
      this.$emit('update', this.attributeKey, updatedValue);
    },
    onDelete() {
      if (this.readOnly) return;
      this.isEditing = false;
      this.v$.$reset();
      this.$emit('delete', this.attributeKey);
    },
    onCopy() {
      this.$emit('copy', this.value);
    },
  },
};
</script>

<template>
  <div class="px-1 py-1 group/attr">
    <!-- Checkbox -->
    <div v-if="isAttributeTypeCheckbox" class="flex items-center gap-2 min-h-9">
      <input
        v-model="editedValue"
        class="!my-0 shrink-0"
        type="checkbox"
        :disabled="readOnly"
        @change="onUpdate"
      />
      <span
        class="flex-1 min-w-0 text-sm font-medium text-n-slate-12 truncate"
        :title="description || label"
      >
        {{ label }}
      </span>
      <NextButton
        v-if="showActions && hasValue && !readOnly"
        v-tooltip.left="$t('CUSTOM_ATTRIBUTES.ACTIONS.DELETE')"
        slate
        xs
        ghost
        icon="i-lucide-trash-2"
        class="opacity-0 group-hover/attr:opacity-100"
        @click="onDelete"
      />
    </div>

    <!-- List -->
    <OutlinedAttributeField
      v-else-if="isAttributeTypeList"
      :label="label"
      :description="description"
      :filled="shellFilled"
      :focused="shellFocused"
    >
      <div
        v-on-clickaway="closeListDropdown"
        class="relative flex items-center w-full min-h-8"
        :class="{ 'cursor-pointer': !readOnly }"
        @click="!readOnly && openListDropdown()"
      >
        <span
          class="text-sm text-n-slate-12 truncate"
          :class="{ 'opacity-0': !hasValue }"
        >
          {{ value || '\u00A0' }}
        </span>
        <DropdownMenu
          v-if="showListDropdown"
          :menu-items="listMenuItems"
          show-search
          class="w-full min-w-[12rem] mt-1 top-full ltr:left-0 rtl:right-0 z-[100]"
          @click.stop
          @action="onSelectListValue"
        />
      </div>
      <template v-if="showActions && hasValue && !readOnly" #trailing>
        <NextButton
          v-tooltip.left="$t('CUSTOM_ATTRIBUTES.ACTIONS.DELETE')"
          xs
          slate
          ghost
          icon="i-lucide-trash-2"
          @click.stop="onDelete"
        />
      </template>
    </OutlinedAttributeField>

    <!-- Multi-list: always expanded (label stays floating; avoids overlap with options) -->
    <OutlinedAttributeField
      v-else-if="isAttributeTypeMultiList"
      :label="label"
      :description="description"
      filled
      :focused="isFocused"
      tall
      @focusin="isFocused = true"
      @focusout="isFocused = false"
    >
      <div class="flex flex-col gap-1.5 py-0.5">
        <label
          v-for="(option, index) in values"
          :key="`${attributeKey}-opt-${index}`"
          class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer"
        >
          <input
            type="checkbox"
            class="!my-0 shrink-0"
            :disabled="readOnly"
            :checked="multiListSelected.includes(option)"
            @change="onToggleMultiListValue(option, $event.target.checked)"
          />
          <span class="min-w-0 break-words">{{ option }}</span>
        </label>
        <p v-if="!values.length" class="m-0 text-sm text-n-slate-11">
          {{ emptyListPlaceholder }}
        </p>
      </div>
    </OutlinedAttributeField>

    <!-- Text / number / currency / percent / link / date / datetime -->
    <OutlinedAttributeField
      v-else
      :label="label"
      :description="description"
      :filled="shellFilled"
      :focused="shellFocused"
      :error="shouldShowErrorMessage"
    >
      <div v-if="isEditing" v-on-clickaway="onClickAway" class="w-full">
        <div class="flex items-center w-full gap-1">
          <span
            v-if="isAttributeTypeCurrency"
            class="text-sm text-n-slate-11 shrink-0"
          >
            {{ currencyPrefix }}
          </span>
          <input
            ref="inputfield"
            v-model="editedValue"
            :type="inputType"
            :min="isAttributeTypeCurrency ? 0 : undefined"
            class="!mb-0 !h-8 !border-0 !shadow-none !outline-none !bg-transparent !px-0 !text-sm w-full"
            autofocus="true"
            :class="{ error: v$.editedValue.$error }"
            @focus="isFocused = true"
            @blur="v$.editedValue.$touch"
            @keyup.enter="onUpdate"
          />
          <span
            v-if="isAttributeTypePercent"
            class="text-sm text-n-slate-11 shrink-0"
          >
            {{ percentSuffix }}
          </span>
          <NextButton
            sm
            icon="i-lucide-check"
            class="h-8 shrink-0"
            @click="onUpdate"
          />
        </div>
        <span
          v-if="shouldShowErrorMessage"
          class="block w-full mt-0.5 text-xs font-normal text-n-ruby-11"
        >
          {{ errorMessage }}
        </span>
      </div>
      <div
        v-else
        class="flex items-center min-h-8 w-full"
        :class="{ 'cursor-pointer': showActions && !readOnly }"
        @click="onEdit"
      >
        <a
          v-if="isAttributeTypeLink && hasValue"
          :href="hrefURL"
          target="_blank"
          rel="noopener noreferrer"
          class="flex-1 min-w-0 text-sm text-n-brand break-all"
          @click.stop
        >
          {{ urlValue }}
        </a>
        <p
          v-else
          class="flex-1 min-w-0 mb-0 text-sm text-n-slate-12 break-all"
          :class="{ 'opacity-0': !hasValue, 'text-n-slate-11': readOnly }"
        >
          {{ displayValue || '\u00A0' }}
        </p>
      </div>

      <template v-if="showActions && hasValue && !isEditing" #trailing>
        <NextButton
          v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.COPY')"
          xs
          slate
          ghost
          icon="i-lucide-clipboard"
          @click.stop="onCopy"
        />
        <NextButton
          v-if="!readOnly"
          v-tooltip.left="$t('CUSTOM_ATTRIBUTES.ACTIONS.DELETE')"
          xs
          slate
          ghost
          icon="i-lucide-trash-2"
          @click.stop="onDelete"
        />
      </template>
    </OutlinedAttributeField>
  </div>
</template>
