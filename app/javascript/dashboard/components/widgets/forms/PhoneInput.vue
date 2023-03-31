<template>
  <div class="phone-input--wrap">
    <div class="country-emoji--wrap" @click="toggleCountryDropdown">
      <h5 v-if="activeCountry.emoji">{{ activeCountry.emoji }}</h5>
      <fluent-icon v-else icon="globe" class="fluent-icon" size="16" />
      <fluent-icon icon="chevron-down" class="fluent-icon" size="12" />
    </div>
    <input
      :value="value"
      type="tel"
      class="phone-input--field"
      :placeholder="placeholder"
      :readonly="readonly"
      :style="styles"
      @input="onChange"
      @blur="onBlur"
    />
    <div
      v-if="showDropdown"
      v-on-clickaway="closeDropdown"
      class="country-dropdown"
    >
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
        v-for="country in filteredCountriesBySearch"
        :key="country.id"
        class="country-dropdown--item"
        :class="{ active: country.id === activeCountryCode }"
        @click="onSelectCountry(country)"
      >
        <span class="country-emoji">{{ country.emoji }}</span>

        <span class="country-name">
          {{ country.name }}
        </span>
        <span class="country-dial-code">{{ country.dial_code }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import countries from 'shared/constants/countries.js';
import parsePhoneNumber from 'libphonenumber-js';

export default {
  mixins: [clickaway],
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
  },
  data() {
    return {
      showDropdown: false,
      searchCountry: '',
      activeCountryCode: '',
    };
  },
  computed: {
    countries() {
      return countries;
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
    value() {
      const phoneNumber = parsePhoneNumber(this.value);
      if (phoneNumber) {
        this.activeCountryCode = phoneNumber.country;
      } else {
        this.activeCountryCode = '';
      }
    },
  },
  mounted() {
    setTimeout(() => {
      this.setActiveCountry();
    }, 10);
  },
  methods: {
    onChange(e) {
      this.$emit('input', e.target.value);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
    onSelectCountry(country) {
      this.activeCountryCode = country.id;
      this.searchCountry = '';
      this.$emit('setCode', country.dial_code);
    },
    setActiveCountry() {
      const { value } = this;
      if (value === '') return;
      const phoneNumber = parsePhoneNumber(value);
      if (phoneNumber) {
        this.activeCountryCode = phoneNumber.country;
      }
    },
    toggleCountryDropdown() {
      this.showDropdown = !this.showDropdown;
      if (this.showDropdown) {
        this.$nextTick(() => {
          this.$refs.searchbar.focus();
        });
      }
    },
    closeDropdown() {
      this.showDropdown = false;
    },
  },
};
</script>
<style scoped lang="scss">
.phone-input--wrap {
  position: relative;

  .country-emoji--wrap {
    position: absolute;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-small);
    background: var(--s-25);
    top: 1px;
    height: 3.7rem;
    width: 5.2rem;
    left: 1px;
    border-radius: var(--border-radius-normal) 0 0 var(--border-radius-normal);
    padding: var(--space-small) var(--space-smaller) var(--space-small)
      var(--space-small);

    h5 {
      margin-bottom: 0;
    }
  }

  .phone-input--field {
    padding-left: var(--space-jumbo);
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
  }
}
</style>
