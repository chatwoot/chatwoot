<template>
  <div class="phone-input--wrap relative mt-2">
    <div
      class="phone-input rounded w-full flex items-center justify-start outline-none border border-solid"
      :class="inputHasError"
    >
      <div
        class="country-emoji--wrap h-full cursor-pointer flex items-center justify-between px-2 py-2"
        :class="dropdownClass"
        @click="toggleCountryDropdown"
      >
        <h5 v-if="activeCountry.emoji" class="text-xl mb-0">
          {{ activeCountry.emoji }}
        </h5>
        <fluent-icon v-else icon="globe" class="fluent-icon" size="20" />
        <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span
        v-if="activeDialCode"
        class="py-2 pr-0 pl-2 text-sm"
        :class="$dm('text-slate-700', 'dark:text-slate-50')"
      >
        {{ activeDialCode }}
      </span>
      <input
        :value="phoneNumber"
        type="phoneInput"
        class="border-0 w-full py-2 pl-2 pr-3 leading-tight outline-none h-full rounded-r"
        name="phoneNumber"
        :placeholder="placeholder"
        :class="inputLightAndDarkModeColor"
        @input="onChange"
        @blur="context.blurHandler"
      />
    </div>
    <div
      v-if="showDropdown"
      ref="dropdown"
      v-on-clickaway="closeDropdown"
      :class="dropdownBackgroundClass"
      class="country-dropdown h-48 overflow-y-auto z-10 absolute top-12 px-0 pt-0 pl-1 pr-1 pb-1 rounded shadow-lg"
    >
      <div class="sticky top-0" :class="dropdownBackgroundClass">
        <input
          ref="searchbar"
          v-model="searchCountry"
          type="text"
          placeholder="Search country"
          class="dropdown-search h-8 text-sm mb-1 mt-1 w-full rounded py-2 px-3 outline-none border border-solid"
          :class="[$dm('bg-slate-50', 'dark:bg-slate-600'), inputBorderColor]"
        />
      </div>
      <div
        v-for="(country, index) in filteredCountriesBySearch"
        ref="dropdownItem"
        :key="index"
        class="country-dropdown--item h-8 flex items-center cursor-pointer rounded py-2 px-2"
        :class="[
          dropdownItemClass,
          country.id === activeCountryCode ? activeDropdownItemClass : '',
          index === selectedIndex ? focusedDropdownItemClass : '',
        ]"
        @click="onSelectCountry(country)"
      >
        <span v-if="country.emoji" class="mr-2 text-xl">{{
          country.emoji
        }}</span>
        <span class="truncate text-sm leading-5">
          {{ country.name }}
        </span>
        <span class="ml-2 text-xs">{{ country.dial_code }}</span>
      </div>
      <div v-if="filteredCountriesBySearch.length === 0">
        <span
          class="text-sm mt-4 justify-center text-center flex"
          :class="$dm('text-slate-700', 'dark:text-slate-50')"
        >
          {{ this.$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_EMPTY') }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import countries from 'shared/constants/countries.js';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import {
  hasPressedArrowUpKey,
  hasPressedArrowDownKey,
  isEnter,
} from 'shared/helpers/KeyboardHelpers';
import FormulateInputMixin from '@braid/vue-formulate/src/FormulateInputMixin';
import darkModeMixin from 'widget/mixins/darkModeMixin';

export default {
  components: {
    FluentIcon,
  },
  mixins: [eventListenerMixins, FormulateInputMixin, darkModeMixin, clickaway],
  props: {
    placeholder: {
      type: String,
      default: '',
    },
    hasErrorInPhoneInput: {
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
      phoneNumber: '',
    };
  },
  computed: {
    dropdownClass() {
      return `${this.$dm('bg-slate-100', 'dark:bg-slate-700')} ${this.$dm(
        'text-slate-700',
        'dark:text-slate-50'
      )}`;
    },
    dropdownBackgroundClass() {
      return `${this.$dm('bg-white', 'dark:bg-slate-700')} ${this.$dm(
        'text-slate-700',
        'dark:text-slate-50'
      )}`;
    },
    dropdownItemClass() {
      return `${this.$dm('text-slate-700', 'dark:text-slate-50')} ${this.$dm(
        'hover:bg-slate-50',
        'dark:hover:bg-slate-600'
      )}`;
    },
    activeDropdownItemClass() {
      return `active ${this.$dm('bg-slate-100', 'dark:bg-slate-800')}`;
    },
    focusedDropdownItemClass() {
      return `focus ${this.$dm('bg-slate-50', 'dark:bg-slate-600')}`;
    },
    inputHasError() {
      return this.hasErrorInPhoneInput
        ? `border-red-200 hover:border-red-300 focus:border-red-300 ${this.inputLightAndDarkModeColor}`
        : `hover:border-black-300 focus:border-black-300 ${this.inputLightAndDarkModeColor} ${this.inputBorderColor}`;
    },
    inputBorderColor() {
      return `${this.$dm('border-black-200', 'dark:border-black-500')}`;
    },
    inputLightAndDarkModeColor() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')} ${this.$dm(
        'text-slate-700',
        'dark:text-slate-50'
      )}`;
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
  methods: {
    setContextValue(code) {
      // This function is used to set the context value.
      // The context value is used to set the value of the phone number field in the pre-chat form.
      this.context.model = `${code}${this.phoneNumber}`;
    },
    onChange(e) {
      if (e.target.value === '') {
        // This is to reset the active country code and dial code when the user clears the phone number field.
        this.activeCountryCode = '';
        this.activeDialCode = '';
      }
      this.phoneNumber = e.target.value;
      // This function is used to set the context value when the user types in the phone number field.
      this.setContextValue();
    },
    dropdownItem() {
      // This function is used to get all the items in the dropdown.
      return Array.from(
        this.$refs.dropdown.querySelectorAll(
          'div.country-dropdown div.country-dropdown--item'
        )
      );
    },
    focusedOrActiveItem(className) {
      // This function is used to get the focused or active item in the dropdown.
      return Array.from(
        this.$refs.dropdown.querySelectorAll(
          `div.country-dropdown div.country-dropdown--item.${className}`
        )
      );
    },
    onKeyDownHandler(e) {
      // Here the code does is to check if the dropdown is open.
      // If it is open, then it checks if the user has pressed the arrow down key or arrow up key.
      // If the user has pressed the arrow down key, then it will increment the selectedIndex by 1.
      // If the user has pressed the arrow up key, then it will decrement the selectedIndex by 1.
      // If the user has pressed the enter key, then it will select the country.
      const { showDropdown, filteredCountriesBySearch, onSelectCountry } = this;
      const { selectedIndex } = this;

      if (showDropdown) {
        if (hasPressedArrowDownKey(e)) {
          e.preventDefault();
          this.selectedIndex = Math.min(
            selectedIndex + 1,
            filteredCountriesBySearch.length - 1
          );
          this.scrollToFocusedOrActiveItem(this.focusedOrActiveItem('focus'));
        } else if (hasPressedArrowUpKey(e)) {
          e.preventDefault();
          this.selectedIndex = Math.max(selectedIndex - 1, 0);
          this.scrollToFocusedOrActiveItem(this.focusedOrActiveItem('focus'));
        } else if (isEnter(e)) {
          e.preventDefault();
          onSelectCountry(filteredCountriesBySearch[selectedIndex]);
        }
      }
    },
    scrollToFocusedOrActiveItem(item) {
      // This function is used to scroll the dropdown to the focused or active item.
      const focusedOrActiveItem = item;
      if (focusedOrActiveItem.length > 0) {
        const dropdown = this.$refs.dropdown;
        const dropdownHeight = dropdown.clientHeight;
        const itemTop = focusedOrActiveItem[0].offsetTop;
        const itemHeight = focusedOrActiveItem[0].offsetHeight;
        const scrollPosition = itemTop - dropdownHeight / 2 + itemHeight / 2;
        dropdown.scrollTo({
          top: scrollPosition,
          behavior: 'auto',
        });
      }
    },
    onSelectCountry(country) {
      this.activeCountryCode = country.id;
      this.searchCountry = '';
      this.activeDialCode = country.dial_code ? country.dial_code : '';
      this.setContextValue(country.dial_code);
      this.closeDropdown();
    },
    toggleCountryDropdown() {
      this.showDropdown = !this.showDropdown;
      this.selectedIndex = -1;
      if (this.showDropdown) {
        this.$nextTick(() => {
          this.$refs.searchbar.focus();
          // This is used to scroll the dropdown to the active item.
          this.scrollToFocusedOrActiveItem(this.focusedOrActiveItem('active'));
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
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
.phone-input--wrap {
  .phone-input {
    height: 2.8rem;

    input:placeholder-shown {
      text-overflow: ellipsis;
    }
  }

  .country-emoji--wrap {
    border-top-left-radius: 0.18rem;
    border-bottom-left-radius: 0.18rem;
    min-width: 3.6rem;
    width: 3.6rem;
  }

  .country-dropdown {
    min-width: 6rem;
    max-width: 14.8rem;
    width: 100%;
  }
}
</style>
