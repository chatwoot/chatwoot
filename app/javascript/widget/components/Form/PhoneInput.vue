<script setup>
import { ref, computed, watch, useTemplateRef, nextTick, unref } from 'vue';
import countriesList from 'shared/constants/countries.js';
import { useDarkMode } from 'widget/composables/useDarkMode';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import {
  getActiveCountryCode,
  getActiveDialCode,
} from 'shared/components/PhoneInput/helper';

const { context } = defineProps({
  context: {
    type: Object,
    default: () => ({}),
  },
});

const localValue = ref(context.value || '');

const { getThemeClass: $dm } = useDarkMode();

const selectedIndex = ref(-1);
const showDropdown = ref(false);
const searchCountry = ref('');
const activeCountryCode = ref(getActiveCountryCode());
const activeDialCode = ref(getActiveDialCode());
const phoneNumber = ref('');

const dropdownRef = useTemplateRef('dropdownRef');
const searchbarRef = useTemplateRef('searchbarRef');

const placeholder = computed(() => context?.attrs?.placeholder || '');
const hasErrorInPhoneInput = computed(() => context.hasErrorInPhoneInput);
const dropdownFirstItemName = computed(() =>
  activeCountryCode.value ? 'Clear selection' : 'Select Country'
);
const countries = computed(() => [
  {
    name: dropdownFirstItemName.value,
    dial_code: '',
    emoji: '',
    id: '',
  },
  ...countriesList,
]);

const dropdownClass = computed(() =>
  $dm('bg-slate-100 text-slate-700', 'dark:bg-slate-700 dark:text-slate-50')
);

const dropdownBackgroundClass = computed(() =>
  $dm('bg-white text-slate-700', 'dark:bg-slate-700 dark:text-slate-50')
);

const dropdownItemClass = computed(() =>
  $dm(
    'text-slate-700 hover:bg-slate-50',
    'dark:text-slate-50 dark:hover:bg-slate-600'
  )
);

const activeDropdownItemClass = computed(
  () => `active ${$dm('bg-slate-100', 'dark:bg-slate-800')}`
);

const focusedDropdownItemClass = computed(
  () => `focus ${$dm('bg-slate-50', 'dark:bg-slate-600')}`
);

const inputLightAndDarkModeColor = computed(() =>
  $dm('bg-white text-slate-700', 'dark:bg-slate-600 dark:text-slate-50')
);

const inputBorderColor = computed(
  () => `${$dm('border-black-200', 'dark:border-black-500')}`
);

const inputHasError = computed(() =>
  hasErrorInPhoneInput.value
    ? `border-red-200 hover:border-red-300 focus:border-red-300 ${inputLightAndDarkModeColor.value}`
    : `hover:border-black-300 focus:border-black-300 ${inputLightAndDarkModeColor.value} ${inputBorderColor.value}`
);

const items = computed(() => {
  return countries.value.filter(country => {
    const { name, dial_code, id } = country;
    const search = searchCountry.value.toLowerCase();
    return (
      name.toLowerCase().includes(search) ||
      dial_code.toLowerCase().includes(search) ||
      id.toLowerCase().includes(search)
    );
  });
});

const activeCountry = computed(() => {
  return countries.value.find(
    country => country.id === activeCountryCode.value
  );
});

watch(items, newItems => {
  if (newItems.length < selectedIndex.value + 1) {
    // Reset the selected index to 0 if the new items length is less than the selected index.
    selectedIndex.value = 0;
  }
});

function setContextValue(code) {
  const safeCode = unref(code);
  // This function is used to set the context value.
  // The context value is used to set the value of the phone number field in the pre-chat form.
  localValue.value = `${safeCode}${phoneNumber.value}`;
  context.node.input(localValue.value);
}

function onChange(e) {
  phoneNumber.value = e.target.value;
  // This function is used to set the context value when the user types in the phone number field.
  setContextValue(activeDialCode.value);
}

function focusedOrActiveItem(className) {
  // This function is used to get the focused or active item in the dropdown.
  if (!showDropdown.value) return [];
  return Array.from(
    dropdownRef.value?.querySelectorAll(
      `div.country-dropdown div.country-dropdown--item.${className}`
    )
  );
}

function scrollToFocusedOrActiveItem(item) {
  // This function is used to scroll the dropdown to the focused or active item.
  const focusedOrActiveItemLocal = item;
  if (focusedOrActiveItemLocal.length > 0) {
    const dropdown = dropdownRef.value;
    const dropdownHeight = dropdown.clientHeight;
    const itemTop = focusedOrActiveItemLocal[0]?.offsetTop;
    const itemHeight = focusedOrActiveItemLocal[0]?.offsetHeight;
    const scrollPosition = itemTop - dropdownHeight / 2 + itemHeight / 2;
    dropdown.scrollTo({
      top: scrollPosition,
      behavior: 'auto',
    });
  }
}

function adjustScroll() {
  nextTick(() => {
    scrollToFocusedOrActiveItem(focusedOrActiveItem('focus'));
  });
}

function adjustSelection(direction) {
  if (!showDropdown.value) return;
  const maxIndex = items.value.length - 1;
  if (direction === 'up') {
    selectedIndex.value =
      selectedIndex.value <= 0 ? maxIndex : selectedIndex.value - 1;
  } else if (direction === 'down') {
    selectedIndex.value =
      selectedIndex.value >= maxIndex ? 0 : selectedIndex.value + 1;
  }
  adjustScroll();
}

function moveSelectionUp() {
  adjustSelection('up');
}
function moveSelectionDown() {
  adjustSelection('down');
}

function closeDropdown() {
  selectedIndex.value = -1;
  showDropdown.value = false;
}

function onSelectCountry(country) {
  activeCountryCode.value = country.id;
  searchCountry.value = '';
  activeDialCode.value = country.dial_code ? country.dial_code : '';
  setContextValue(country.dial_code);
  closeDropdown();
}

function toggleCountryDropdown() {
  showDropdown.value = !showDropdown.value;
  selectedIndex.value = -1;
  if (showDropdown.value) {
    nextTick(() => {
      searchbarRef.value.focus();
      // This is used to scroll the dropdown to the active item.
      scrollToFocusedOrActiveItem(focusedOrActiveItem('active'));
    });
  }
}

function onSelect() {
  if (!showDropdown.value || selectedIndex.value === -1) return;
  onSelectCountry(items.value[selectedIndex.value]);
}
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
        :class="$dm('text-slate-700', 'dark:text-slate-50')"
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
      ref="dropdownRef"
      v-on-clickaway="closeDropdown"
      :class="dropdownBackgroundClass"
      class="absolute z-10 h-48 px-0 pt-0 pb-1 pl-1 pr-1 overflow-y-auto rounded shadow-lg country-dropdown top-12"
      @keydown.up="moveSelectionUp"
      @keydown.down="moveSelectionDown"
      @keydown.enter="onSelect"
    >
      <div class="sticky top-0" :class="dropdownBackgroundClass">
        <input
          ref="searchbarRef"
          v-model="searchCountry"
          type="text"
          :placeholder="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_SEARCH')"
          class="w-full h-8 px-3 py-2 mt-1 mb-1 text-sm border border-solid rounded outline-none dropdown-search"
          :class="[$dm('bg-slate-50', 'dark:bg-slate-600'), inputBorderColor]"
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
          :class="$dm('text-slate-700', 'dark:text-slate-50')"
        >
          {{ $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_EMPTY') }}
        </span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import 'widget/assets/scss/variables.scss';

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
