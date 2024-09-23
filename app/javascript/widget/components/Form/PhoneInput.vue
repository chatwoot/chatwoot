<script>
import countries from 'shared/constants/countries.js';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import FormulateInputMixin from '@braid/vue-formulate/src/FormulateInputMixin';
import { useDarkMode } from 'widget/composables/useDarkMode';
import {
  getActiveCountryCode,
  getActiveDialCode,
} from 'shared/components/PhoneInput/helper';

export default {
  components: {
    FluentIcon,
  },
  mixins: [FormulateInputMixin],
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
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
  },
  data() {
    return {
      selectedIndex: -1,
      showDropdown: false,
      searchCountry: '',
      activeCountryCode: getActiveCountryCode(),
      activeDialCode: getActiveDialCode(),
      phoneNumber: '',
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
    dropdownClass() {
      return `${this.getThemeClass(
        'bg-slate-100',
        'dark:bg-slate-700'
      )} ${this.getThemeClass('text-slate-700', 'dark:text-slate-50')}`;
    },
    dropdownBackgroundClass() {
      return `${this.getThemeClass(
        'bg-white',
        'dark:bg-slate-700'
      )} ${this.getThemeClass('text-slate-700', 'dark:text-slate-50')}`;
    },
    dropdownItemClass() {
      return `${this.getThemeClass(
        'text-slate-700',
        'dark:text-slate-50'
      )} ${this.getThemeClass('hover:bg-slate-50', 'dark:hover:bg-slate-600')}`;
    },
    activeDropdownItemClass() {
      return `active ${this.getThemeClass(
        'bg-slate-100',
        'dark:bg-slate-800'
      )}`;
    },
    focusedDropdownItemClass() {
      return `focus ${this.getThemeClass('bg-slate-50', 'dark:bg-slate-600')}`;
    },
    inputHasError() {
      return this.hasErrorInPhoneInput
        ? `border-red-200 hover:border-red-300 focus:border-red-300 ${this.inputLightAndDarkModeColor}`
        : `hover:border-black-300 focus:border-black-300 ${this.inputLightAndDarkModeColor} ${this.inputBorderColor}`;
    },
    inputBorderColor() {
      return `${this.getThemeClass(
        'border-black-200',
        'dark:border-black-500'
      )}`;
    },
    inputLightAndDarkModeColor() {
      return `${this.getThemeClass(
        'bg-white',
        'dark:bg-slate-600'
      )} ${this.getThemeClass('text-slate-700', 'dark:text-slate-50')}`;
    },
    items() {
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
      return (
        this.countries.find(country => country.id === this.activeCountryCode) ||
        ''
      );
    },
  },
  watch: {
    items(newItems) {
      if (newItems.length < this.selectedIndex + 1) {
        // Reset the selected index to 0 if the new items length is less than the selected index.
        this.selectedIndex = 0;
      }
    },
  },
  methods: {
    setContextValue(code) {
      // This function is used to set the context value.
      // The context value is used to set the value of the phone number field in the pre-chat form.
      this.context.model = `${code}${this.phoneNumber}`;
    },
    dynamicallySetCountryCode(value) {
      // This function is used to set the country code dynamically.
      // The country and dial code is used to set from the value of the phone number field in the pre-chat form.
      if (!value) return;

      // check the number first four digit and check weather it is available in the countries array or not.
      const country = countries.find(code => value.startsWith(code.dial_code));
      if (country) {
        // if it is available then set the country code and dial code.
        this.activeCountryCode = country.id;
        this.activeDialCode = country.dial_code;
        // set the phone number without dial code.
        this.phoneNumber = value.replace(country.dial_code, '');
      }
    },
    onChange(e) {
      this.phoneNumber = e.target.value;
      this.dynamicallySetCountryCode(this.phoneNumber);
      // This function is used to set the context value when the user types in the phone number field.
      this.setContextValue(this.activeDialCode);
    },
    dropdownItem() {
      // This function is used to get all the items in the dropdown.
      if (!this.showDropdown) return [];
      return Array.from(
        this.$refs.dropdown?.querySelectorAll(
          'div.country-dropdown div.country-dropdown--item'
        )
      );
    },
    focusedOrActiveItem(className) {
      // This function is used to get the focused or active item in the dropdown.
      if (!this.showDropdown) return [];
      return Array.from(
        this.$refs.dropdown?.querySelectorAll(
          `div.country-dropdown div.country-dropdown--item.${className}`
        )
      );
    },
    adjustScroll() {
      this.$nextTick(() => {
        this.scrollToFocusedOrActiveItem(this.focusedOrActiveItem('focus'));
      });
    },
    adjustSelection(direction) {
      if (!this.showDropdown) return;
      const maxIndex = this.items.length - 1;
      if (direction === 'up') {
        this.selectedIndex =
          this.selectedIndex <= 0 ? maxIndex : this.selectedIndex - 1;
      } else if (direction === 'down') {
        this.selectedIndex =
          this.selectedIndex >= maxIndex ? 0 : this.selectedIndex + 1;
      }
      this.adjustScroll();
    },
    moveSelectionUp() {
      this.adjustSelection('up');
    },
    moveSelectionDown() {
      this.adjustSelection('down');
    },
    onSelect() {
      if (!this.showDropdown || this.selectedIndex === -1) return;
      this.onSelectCountry(this.items[this.selectedIndex]);
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

<template>
  <div class="relative mt-2 phone-input--wrap">
    <div
      class="flex items-center justify-start w-full border border-solid rounded outline-none phone-input"
      :class="inputHasError"
    >
      <div
        class="flex items-center justify-between h-full px-2 py-2 cursor-pointer country-emoji--wrap"
        :class="dropdownClass"
        @click="toggleCountryDropdown"
      >
        <h5 v-if="activeCountry.emoji" class="mb-0 text-xl">
          {{ activeCountry.emoji }}
        </h5>
        <FluentIcon v-else icon="globe" class="fluent-icon" size="20" />
        <FluentIcon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span
        v-if="activeDialCode"
        class="py-2 pl-2 pr-0 text-base"
        :class="getThemeClass('text-slate-700', 'dark:text-slate-50')"
      >
        {{ activeDialCode }}
      </span>
      <input
        :value="phoneNumber"
        type="phoneInput"
        class="w-full h-full py-2 pl-2 pr-3 leading-tight border-0 rounded-r outline-none"
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
      class="absolute z-10 h-48 px-0 pt-0 pb-1 pl-1 pr-1 overflow-y-auto rounded shadow-lg country-dropdown top-12"
      @keydown.up="moveSelectionUp"
      @keydown.down="moveSelectionDown"
      @keydown.enter="onSelect"
    >
      <div class="sticky top-0" :class="dropdownBackgroundClass">
        <input
          ref="searchbar"
          v-model="searchCountry"
          type="text"
          :placeholder="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_SEARCH')"
          class="w-full h-8 px-3 py-2 mt-1 mb-1 text-sm border border-solid rounded outline-none dropdown-search"
          :class="[
            getThemeClass('bg-slate-50', 'dark:bg-slate-600'),
            inputBorderColor,
          ]"
        />
      </div>
      <div
        v-for="(country, index) in items"
        :key="index"
        class="flex items-center h-8 px-2 py-2 rounded cursor-pointer country-dropdown--item"
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
        <span class="text-sm leading-5 truncate">
          {{ country.name }}
        </span>
        <span class="ml-2 text-xs">{{ country.dial_code }}</span>
      </div>
      <div v-if="items.length === 0">
        <span
          class="flex justify-center mt-4 text-sm text-center"
          :class="getThemeClass('text-slate-700', 'dark:text-slate-50')"
        >
          {{ $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_EMPTY') }}
        </span>
      </div>
    </div>
  </div>
</template>

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
    border-bottom-left-radius: 0.18rem;
    border-top-left-radius: 0.18rem;
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
