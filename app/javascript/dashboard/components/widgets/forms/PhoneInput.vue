<template>
  <div class="phone-input--wrap relative">
    <div class="phone-input" :class="{ 'has-error': error }">
      <div
        class="cursor-pointer py-2 pr-1.5 pl-2 rounded-tl-md rounded-bl-md flex items-center justify-center gap-1.5 bg-slate-25 dark:bg-slate-700 h-10 w-14"
        @click="toggleCountryDropdown"
      >
        <h5 v-if="activeCountry" class="mb-0">
          {{ activeCountry.emoji }}
        </h5>
        <fluent-icon v-else icon="globe" class="fluent-icon" size="16" />
        <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span
        v-if="activeDialCode"
        class="flex bg-white dark:bg-slate-900 font-medium text-slate-800 dark:text-slate-100 font-normal text-base leading-normal py-2 pl-2 pr-0"
      >
        {{ activeDialCode }}
      </span>
      <input
        :value="phoneNumber"
        type="tel"
        class="phone-input--field"
        :placeholder="placeholder"
        :readonly="readonly"
        :style="styles"
        @input="onChange"
        @blur="onBlur"
      />
    </div>
    <div v-if="showDropdown" ref="dropdown" class="country-dropdown">
      <div class="dropdown-search--wrap">
        <input
          ref="searchbar"
          v-model="searchCountry"
          type="text"
          placeholder="Search"
          class="dropdown-search"
        />
      </div>
      <div
        v-for="(country, index) in filteredCountriesBySearch"
        ref="dropdownItem"
        :key="index"
        class="country-dropdown--item"
        :class="{
          active: country.id === activeCountryCode,
          focus: index === selectedIndex,
        }"
        @click="onSelectCountry(country)"
      >
        <span class="text-base mr-1">{{ country.emoji }}</span>

        <span
          class="max-w-[7.5rem] overflow-hidden text-ellipsis whitespace-nowrap"
        >
          {{ country.name }}
        </span>
        <span class="ml-1 text-slate-300 dark:text-slate-300 text-xs">{{
          country.dial_code
        }}</span>
      </div>
      <div v-if="filteredCountriesBySearch.length === 0">
        <span
          class="flex items-center justify-center text-sm text-slate-500 dark:text-slate-300 mt-4"
        >
          No results found
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import countries from 'shared/constants/countries.js';
import parsePhoneNumber from 'libphonenumber-js';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import {
  hasPressedArrowUpKey,
  hasPressedArrowDownKey,
  isEnter,
} from 'shared/helpers/KeyboardHelpers';

export default {
  mixins: [eventListenerMixins],
  props: {
    value: {
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
  data() {
    return {
      countries: [
        {
          name: 'Select Country',
          dial_code: '',
          emoji: '',
          id: '',
        },
        ...countries,
      ],
      selectedIndex: -1,
      showDropdown: false,
      searchCountry: '',
      activeCountryCode: '',
      activeDialCode: '',
      phoneNumber: this.value,
    };
  },
  computed: {
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
    value() {
      const number = parsePhoneNumber(this.value);
      if (number) {
        this.activeCountryCode = number.country;
        this.activeDialCode = `+${number.countryCallingCode}`;
        this.phoneNumber = this.value.replace(
          `+${number.countryCallingCode}`,
          ''
        );
      }
    },
  },
  mounted() {
    window.addEventListener('mouseup', this.onOutsideClick);
    this.setActiveCountry();
  },
  beforeDestroy() {
    window.removeEventListener('mouseup', this.onOutsideClick);
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
      this.$emit('input', e.target.value, this.activeDialCode);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
    dropdownItem() {
      return Array.from(
        this.$refs.dropdown.querySelectorAll(
          'div.country-dropdown div.country-dropdown--item'
        )
      );
    },
    focusedItem() {
      return Array.from(
        this.$refs.dropdown.querySelectorAll('div.country-dropdown div.focus')
      );
    },
    focusedItemIndex() {
      return Array.from(this.dropdownItem()).indexOf(this.focusedItem()[0]);
    },
    onKeyDownHandler(e) {
      const { showDropdown, filteredCountriesBySearch, onSelectCountry } = this;
      const { selectedIndex } = this;

      if (showDropdown) {
        if (hasPressedArrowDownKey(e)) {
          e.preventDefault();
          this.selectedIndex = Math.min(
            selectedIndex + 1,
            filteredCountriesBySearch.length - 1
          );
          this.$refs.dropdown.scrollTop = this.focusedItemIndex() * 28;
        } else if (hasPressedArrowUpKey(e)) {
          e.preventDefault();
          this.selectedIndex = Math.max(selectedIndex - 1, 0);
          this.$refs.dropdown.scrollTop = this.focusedItemIndex() * 28 - 56;
        } else if (isEnter(e)) {
          e.preventDefault();
          onSelectCountry(filteredCountriesBySearch[selectedIndex]);
        }
      }
    },
    onSelectCountry(country) {
      this.activeCountryCode = country.id;
      this.searchCountry = '';
      this.activeDialCode = country.dial_code;
      this.$emit('setCode', country.dial_code);
      this.closeDropdown();
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
<style scoped lang="scss">
.phone-input--wrap {
  .phone-input {
    @apply flex items-center dark:bg-slate-900 justify-start mb-4 rounded-md border border-solid border-slate-200 dark:border-slate-600;

    &.has-error {
      @apply border border-solid border-red-400 dark:border-red-400;
    }
  }

  .phone-input--field {
    @apply mb-0 rounded-tl-none rounded-bl-none border-0 w-full dark:bg-slate-900 text-base px-1.5;

    &::placeholder {
      @apply font-normal;
    }
  }

  .country-dropdown {
    @apply z-10 absolute h-60 w-[12.5rem] shadow-md overflow-y-auto top-10 rounded px-0 pt-0 pb-1 bg-white dark:bg-slate-900;

    .dropdown-search--wrap {
      @apply top-0 sticky bg-white dark:bg-slate-900 p-1;

      .dropdown-search {
        @apply h-8 mb-0 text-sm border border-solid border-slate-200 dark:border-slate-600;
      }
    }

    .country-dropdown--item {
      @apply flex items-center h-7 py-0 px-1 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700;

      &.active {
        @apply bg-slate-50 dark:bg-slate-700;
      }

      &.focus {
        @apply bg-slate-25 dark:bg-slate-800;
      }
    }
  }
}
</style>
