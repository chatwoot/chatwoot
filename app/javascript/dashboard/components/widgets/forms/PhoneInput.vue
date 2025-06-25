<template>
  <div class="phone-input--wrap">
    <div class="phone-input" :class="{ 'has-error': error }">
      <div class="country-emoji--wrap" @click="toggleCountryDropdown">
        <h5 v-if="activeCountry.emoji">{{ activeCountry.emoji }}</h5>
        <fluent-icon v-else icon="globe" class="fluent-icon" size="16" />
        <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
      </div>
      <span v-if="activeDialCode" class="country-dial--code">
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
        <span class="country-emoji">{{ country.emoji }}</span>

        <span class="country-name">
          {{ country.name }}
        </span>
        <span class="country-dial-code">{{ country.dial_code }}</span>
      </div>
      <div v-if="filteredCountriesBySearch.length === 0">
        <span class="no-results">No results found</span>
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
  position: relative;

  .phone-input {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    margin-bottom: var(--space-normal);
    border: 1px solid var(--s-200);
    border-radius: var(--border-radius-normal);

    &.has-error {
      border: 1px solid var(--r-400);
    }
  }

  .country-emoji--wrap {
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-small);
    background: var(--s-25);
    height: 4rem;
    width: 5.2rem;
    border-radius: var(--border-radius-normal) 0 0 var(--border-radius-normal);
    padding: var(--space-small) var(--space-smaller) var(--space-small)
      var(--space-small);

    h5 {
      margin-bottom: 0;
    }
  }

  .country-dial--code {
    display: flex;
    color: var(--s-300);
    font-size: var(--space-normal);
    font-weight: normal;
    line-height: 1.5;
    padding: var(--space-small) 0 var(--space-small) var(--space-small);
  }

  .phone-input--field {
    margin-bottom: 0;
    border: 0;
  }

  .country-dropdown {
    z-index: var(--z-index-low);
    position: absolute;
    height: var(--space-giga);
    width: 20rem;
    overflow-y: auto;
    top: 4rem;
    border-radius: var(--border-radius-default);
    padding: 0 0 var(--space-smaller) 0;
    background-color: var(--white);
    box-shadow: var(--shadow-context-menu);
    border-radius: var(--border-radius-normal);

    .dropdown-search--wrap {
      top: 0;
      position: sticky;
      background-color: var(--white);
      padding: var(--space-smaller);

      .dropdown-search {
        height: var(--space-large);
        margin-bottom: 0;
        font-size: var(--font-size-small);
        border: 1px solid var(--s-200) !important;
      }
    }

    .country-dropdown--item {
      display: flex;
      align-items: center;
      height: 2.8rem;
      padding: 0 var(--space-smaller);
      cursor: pointer;

      &.active {
        background-color: var(--s-50);
      }

      &.focus {
        background-color: var(--s-25);
      }

      &:hover {
        background-color: var(--s-50);
      }

      .country-emoji {
        font-size: var(--font-size-default);
        margin-right: var(--space-smaller);
      }

      .country-name {
        max-width: 12rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .country-dial-code {
        margin-left: var(--space-smaller);
        color: var(--s-300);
        font-size: var(--font-size-mini);
      }
    }

    .no-results {
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--s-500);
      margin-top: var(--space-normal);
    }
  }
}
</style>
