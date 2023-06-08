<template>
  <div class="phone-input--wrap relative mt-2">
    <div
      class="phone-input rounded w-full flex items-center justify-start outline-none border border-solid"
      :class="inputHasError"
    >
      <div
        class="country-emoji--wrap h-full cursor-pointer flex items-center justify-between pt-2 pr-2 pb-2 pl-2 rounded-l-sm"
        :class="dropdownClass"
        @click="toggleCountryDropdown"
      >
        <h5 v-if="activeCountry.emoji" class="text-xl mb-0">
          {{ activeCountry.emoji }}
        </h5>
        <fluent-icon v-else icon="globe" class="fluent-icon" size="18" />
        <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span
        v-if="activeDialCode"
        class="pt-2 pr-0 pb-2 pl-2 text-sm"
        :class="$dm('text-slate-700', 'dark:text-slate-50')"
      >
        {{ activeDialCode }}
      </span>
      <input
        :value="phoneNumber"
        type="phoneInput"
        class="border-0 w-full py-2 px-3 leading-tight outline-none h-full"
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
      :class="dropdownClass"
      class="country-dropdown h-48 overflow-y-auto z-10 absolute top-12 px-0 pt-0 pl-1 pr-1 pb-1 rounded shadow-lg"
    >
      <div class="sticky top-0" :class="dropdownClass">
        <input
          ref="searchbar"
          v-model="searchCountry"
          type="text"
          placeholder="Search"
          class="dropdown-search h-8 text-sm mb-1 mt-1 w-full rounded py-2 px-3 outline-none border border-solid"
          :class="[$dm('bg-slate-50', 'dark:bg-slate-800'), inputBorderColor]"
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
          No results found
        </span>
      </div>
    </div>
  </div>
</template>

<script>
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
  mixins: [eventListenerMixins, FormulateInputMixin, darkModeMixin],
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
    dropdownItemClass() {
      return `${this.$dm('text-slate-700', 'dark:text-slate-50')} ${this.$dm(
        'hover:bg-slate-50',
        'dark:hover:bg-slate-600'
      )}`;
    },
    activeDropdownItemClass() {
      return `active ${this.$dm('bg-slate-200', 'dark:bg-slate-800')}`;
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
  mounted() {
    window.addEventListener('mouseup', this.onOutsideClick);
  },
  beforeDestroy() {
    window.removeEventListener('mouseup', this.onOutsideClick);
  },
  methods: {
    setContextValue(code) {
      this.context.model = `${code}${this.phoneNumber}`;
    },
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
      if (e.target.value === '') {
        this.activeCountryCode = '';
        this.activeDialCode = '';
      }
      this.phoneNumber = e.target.value;
      this.setContextValue();
    },
    dropdownItem() {
      return Array.from(
        this.$refs.dropdown.querySelectorAll(
          'div.country-dropdown div.country-dropdown--item'
        )
      );
    },
    focusedOrActiveItem(className) {
      return Array.from(
        this.$refs.dropdown.querySelectorAll(
          `div.country-dropdown div.country-dropdown--item.${className}`
        )
      );
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
      const focusedItem = item;
      if (focusedItem.length > 0) {
        const dropdown = this.$refs.dropdown;
        const dropdownHeight = dropdown.clientHeight;
        const itemTop = focusedItem[0].offsetTop;
        const itemHeight = focusedItem[0].offsetHeight;
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
    width: 3.6rem;
    min-width: 3.6rem;
  }

  .country-dropdown {
    width: 14.4rem;
  }
}
</style>
