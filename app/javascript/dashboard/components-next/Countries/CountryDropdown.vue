<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import countries from 'shared/constants/countries.js';
import Button from 'dashboard/components-next/button/Button.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  placeholder: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['change']);
const countryCode = defineModel({
  type: String,
  default: '',
});

const { t } = useI18n();

const [showCountryDropdown, toggleCountryDropdown] = useToggle();
const searchQuery = ref('');

const countryOptions = computed(() =>
  countries.map(({ name, id }) => ({
    label: name,
    value: id,
    action: 'select',
    isSelected: countryCode.value === id,
  }))
);

const filteredCountries = computed(() => {
  if (!searchQuery.value) return countryOptions.value;

  const query = searchQuery.value.toLowerCase();
  return countryOptions.value.filter(country =>
    country.label.toLowerCase().includes(query)
  );
});

const selectedCountry = computed(() => {
  return countries.find(country => country.id === countryCode.value);
});

const buttonLabel = computed(() => {
  if (selectedCountry.value) {
    return selectedCountry.value.name;
  }
  return props.placeholder;
});

const handleAction = ({ value }) => {
  if (countryCode.value === value) {
    countryCode.value = '';
    emit('change', null);
  } else {
    countryCode.value = value;
    const country = countries.find(c => c.id === value);
    emit('change', country);
  }
  toggleCountryDropdown(false);
};

const handleSearch = query => {
  searchQuery.value = query;
};

const handleClickOutside = () => {
  toggleCountryDropdown(false);
};
</script>

<template>
  <div v-on-click-outside="handleClickOutside" class="relative w-full min-w-0">
    <Button
      slate
      sm
      :label="buttonLabel"
      :icon="!selectedCountry ? 'i-lucide-flag' : ''"
      :variant="showCountryDropdown ? 'faded' : 'solid'"
      no-animation
      class="w-full !justify-start -outline-offset-1"
      @click="toggleCountryDropdown()"
    >
      <template v-if="selectedCountry" #icon>
        <Flag :country="selectedCountry.id" class="size-3" />
      </template>
    </Button>

    <Transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <DropdownMenu
        v-if="showCountryDropdown"
        :menu-items="filteredCountries"
        show-search
        :search-placeholder="t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')"
        class="max-h-60 overflow-y-auto absolute z-50 w-full mt-1 top-full min-w-40"
        @action="handleAction"
        @search="handleSearch"
      >
        <template #icon="{ item }">
          <Flag :country="item.value" class="size-3" />
        </template>
      </DropdownMenu>
    </Transition>
  </div>
</template>
