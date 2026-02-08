<script setup>
import { ref, computed, watch, useTemplateRef, nextTick, unref } from 'vue';
import countriesList from 'shared/constants/countries.js';
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

const selectedIndex = ref(-1);
const showDropdown = ref(false);
const searchCountry = ref('');
const activeCountryCode = ref(getActiveCountryCode());
const activeDialCode = ref(getActiveDialCode());
const phoneNumber = ref('');

const dropdownRef = useTemplateRef('dropdownRef');
const searchbarRef = useTemplateRef('searchbarRef');

const placeholder = computed(() => context?.attrs?.placeholder || '');
const hasErrorInPhoneInput = computed(() => context?.state?.invalid);
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
      class="flex items-center justify-start outline-none phone-input rounded-lg box-border bg-n-background dark:bg-n-alpha-2 border-none outline outline-1 outline-offset-[-1px] text-sm w-full text-n-slate-12 focus-within:outline-n-brand focus-within:ring-1 focus-within:ring-n-brand"
      :class="{
        'outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9':
          hasErrorInPhoneInput,
        'outline-n-weak': !hasErrorInPhoneInput,
      }"
    >
      <div
        class="flex items-center justify-between h-[2.625rem] px-2 py-2 cursor-pointer bg-n-alpha-1 dark:bg-n-solid-1 ltr:rounded-bl-lg rtl:rounded-br-lg ltr:rounded-tl-lg rtl:rounded-tr-lg min-w-[3.6rem] w-[3.6rem]"
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
        class="py-2 ltr:pl-2 rtl:pr-2 text-base text-n-slate-11"
      >
        {{ activeDialCode }}
      </span>
      <input
        :value="phoneNumber"
        type="phoneInput"
        class="w-full h-full !py-3 pl-2 pr-3 leading-tight rounded-r !outline-none focus:!ring-0 !bg-transparent dark:!bg-transparent"
        name="phoneNumber"
        :placeholder="placeholder"
        @input="onChange"
        @blur="context.blurHandler"
      />
    </div>
    <div
      v-if="showDropdown"
      ref="dropdownRef"
      v-on-clickaway="closeDropdown"
      class="country-dropdown absolute bg-n-background text-n-slate-12 dark:bg-n-solid-3 z-10 h-48 px-0 pt-0 pb-1 pl-1 pr-1 overflow-y-auto rounded-lg shadow-lg top-12 w-full min-w-24 max-w-[14.8rem]"
      @keydown.up="moveSelectionUp"
      @keydown.down="moveSelectionDown"
      @keydown.enter="onSelect"
    >
      <div
        class="sticky top-0 bg-n-background text-n-slate-12 dark:bg-n-solid-3"
      >
        <input
          ref="searchbarRef"
          v-model="searchCountry"
          type="text"
          :placeholder="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_SEARCH')"
          class="w-full h-8 !ring-0 px-3 py-2 mt-1 mb-1 text-sm rounded bg-n-alpha-black2"
        />
      </div>
      <div
        v-for="(country, index) in items"
        :key="index"
        class="flex items-center h-8 px-2 py-2 rounded cursor-pointer country-dropdown--item text-n-slate-12 dark:hover:bg-n-solid-2 hover:bg-n-alpha-2"
        :class="[
          country.id === activeCountryCode &&
            'active bg-n-alpha-1 dark:bg-n-solid-1',
          index === selectedIndex && 'focus dark:bg-n-solid-2 bg-n-alpha-2',
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
          class="flex justify-center mt-4 text-sm text-center text-n-slate-11"
        >
          {{ $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DROPDOWN_EMPTY') }}
        </span>
      </div>
    </div>
  </div>
</template>
