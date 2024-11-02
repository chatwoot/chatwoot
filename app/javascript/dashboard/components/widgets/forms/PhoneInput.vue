<script>
import countries from 'shared/constants/countries.js';
import parsePhoneNumber from 'libphonenumber-js';
import {
  getActiveCountryCode,
  getActiveDialCode,
} from 'shared/components/PhoneInput/helper';

export default {
  props: {
    modelValue: {
      type: [String, Number],
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    readonly: {
      type: Boolean,
      default: false,
    },
    styles: {
      type: Object,
      default: () => {},
    },
    error: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['blur', 'setCode', 'update:modelValue'],
  data() {
    return {
      selectedIndex: -1,
      showDropdown: false,
      searchCountry: '',
      activeCountryCode: getActiveCountryCode(),
      activeDialCode: getActiveDialCode(),
      phoneNumber: this.modelValue,
    };
  },
  computed: {
    countries() {
      return [
        {
          name: this.dropdownFirstItemName,
          dial_code: '',
          emoji: '',
          id: '',
        },
        ...countries,
      ];
    },
    dropdownFirstItemName() {
      return this.activeCountryCode ? 'Clear selection' : 'Select Country';
    },
    filteredCountriesBySearch() {
      return this.countries.filter(country => {
        const { name, dial_code, id } = country;
        const search = this.searchCountry.toLowerCase();
        return (
          name.toLowerCase().includes(search) ||
          dial_code.toLowerCase().includes(search) ||
          id.toLowerCase().includes(search)
        );
      });
    },
    activeCountry() {
      if (this.activeCountryCode) {
        return this.countries.find(
          country => country.id === this.activeCountryCode
        );
      }
      return '';
    },
  },
  watch: {
    modelValue() {
      const number = parsePhoneNumber(this.modelValue);
      if (number) {
        this.activeCountryCode = number.country;
        this.activeDialCode = `+${number.countryCallingCode}`;
        this.phoneNumber = this.modelValue.replace(
          `+${number.countryCallingCode}`,
          ''
        );
      }
    },
  },
  mounted() {
    this.setActiveCountry();
  },
  methods: {
    onOutsideClick(e) {
      if (
        this.showDropdown &&
        e.target !== this.$refs.dropdown &&
        !this.$refs.dropdown.contains(e.target)
      ) {
        this.closeDropdown();
      }
    },
    onChange(e) {
      this.phoneNumber = e.target.value;
      this.$emit('update:modelValue', e.target.value);
      this.$emit('setCode', this.activeDialCode);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
    onSearchCountry() {
      // Reset selected index to 0
      this.selectedIndex = 0;
    },
    moveUp() {
      if (!this.showDropdown) return;
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
      this.scrollToSelected();
    },
    moveDown() {
      if (!this.showDropdown) return;
      this.selectedIndex = Math.min(
        this.selectedIndex + 1,
        this.filteredCountriesBySearch.length - 1
      );
      this.scrollToSelected();
    },
    scrollToSelected() {
      this.$nextTick(() => {
        const dropdown = this.$refs.dropdown;
        const selectedItem = this.$refs.dropdownItem[this.selectedIndex];
        const dropdownSearchbarHeight = 40;
        if (selectedItem) {
          const selectedItemTop = selectedItem.offsetTop;
          dropdown.scrollTop = selectedItemTop - dropdownSearchbarHeight;
        }
      });
    },
    onSelectCountry(country) {
      if (!country || !this.showDropdown) return;
      this.activeCountryCode = country.id;
      this.searchCountry = '';
      this.activeDialCode = country.dial_code;
      this.$emit('setCode', country.dial_code);
      this.closeDropdown();
      this.$refs.phoneNumberInput.focus();
    },
    setActiveCountry() {
      const { phoneNumber } = this;
      if (!phoneNumber) return;
      const number = parsePhoneNumber(phoneNumber);
      if (number) {
        this.activeCountryCode = number.country;
        this.activeDialCode = number.countryCallingCode;
      }
    },
    toggleCountryDropdown() {
      this.showDropdown = !this.showDropdown;
      this.selectedIndex = -1;
      if (this.showDropdown) {
        this.$nextTick(() => {
          this.$refs.searchbar.focus();
        });
      }
    },
    closeDropdown() {
      this.selectedIndex = -1;
      this.showDropdown = false;
    },
  },
};
</script>

<template>
  <div class="relative phone-input--wrap">
    <div
      class="flex items-center justify-start border border-solid rounded-md dark:bg-slate-900"
      :class="
        error
          ? 'border border-solid border-red-400 dark:border-red-400 mb-1'
          : 'mb-4 border-slate-200 dark:border-slate-600'
      "
    >
      <div
        class="cursor-pointer py-2 pr-1.5 pl-2 rounded-tl-md rounded-bl-md flex items-center justify-center gap-1.5 bg-slate-25 dark:bg-slate-700 h-10 w-14"
        @click.prevent="toggleCountryDropdown"
      >
        <h5 v-if="activeCountry" class="mb-0">
          {{ activeCountry.emoji }}
        </h5>
        <fluent-icon v-else icon="globe" class="fluent-icon" size="16" />
        <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span
        v-if="activeDialCode"
        class="flex py-2 pl-2 pr-0 text-base font-normal leading-normal bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100"
      >
        {{ activeDialCode }}
      </span>
      <input
        ref="phoneNumberInput"
        :value="phoneNumber"
        type="tel"
        class="!mb-0 !rounded-tl-none !rounded-bl-none !border-0 font-normal !w-full dark:!bg-slate-900 text-base !px-1.5 placeholder:font-normal"
        :placeholder="placeholder"
        :readonly="readonly"
        :style="styles"
        @input="onChange"
        @blur="onBlur"
      />
    </div>
    <div
      v-if="showDropdown"
      ref="dropdown"
      v-on-clickaway="onOutsideClick"
      tabindex="0"
      class="z-10 absolute h-60 w-[12.5rem] shadow-md overflow-y-auto top-10 rounded px-0 pt-0 pb-1 bg-white dark:bg-slate-900"
      @keydown.prevent.up="moveUp"
      @keydown.prevent.down="moveDown"
      @keydown.prevent.enter="
        onSelectCountry(filteredCountriesBySearch[selectedIndex])
      "
    >
      <div class="sticky top-0 p-1 bg-white dark:bg-slate-900">
        <input
          ref="searchbar"
          v-model="searchCountry"
          type="text"
          :placeholder="$t('GENERAL.PHONE_INPUT.PLACEHOLDER')"
          class="!h-8 !mb-0 !text-sm !border !border-solid !border-slate-2000 dark:!border-slate-6000"
          @input="onSearchCountry"
        />
      </div>
      <div
        v-for="(country, index) in filteredCountriesBySearch"
        ref="dropdownItem"
        :key="index"
        class="flex items-center px-1 py-0 cursor-pointer h-7 hover:bg-slate-50 dark:hover:bg-slate-700"
        :class="{
          'bg-slate-50 dark:bg-slate-700': country.id === activeCountryCode,
          'bg-slate-25 dark:bg-slate-800': index === selectedIndex,
        }"
        @click="onSelectCountry(country)"
      >
        <span class="mr-1 text-base">{{ country.emoji }}</span>

        <span
          class="max-w-[7.5rem] overflow-hidden text-ellipsis whitespace-nowrap"
        >
          {{ country.name }}
        </span>
        <span class="ml-1 text-xs text-slate-300 dark:text-slate-300">{{
          country.dial_code
        }}</span>
      </div>
      <div v-if="filteredCountriesBySearch.length === 0">
        <span
          class="flex items-center justify-center mt-4 text-sm text-slate-500 dark:text-slate-300"
        >
          {{ $t('GENERAL.PHONE_INPUT.EMPTY_STATE') }}
        </span>
      </div>
    </div>
  </div>
</template>
