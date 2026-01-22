<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { debounce } from '@chatwoot/utils';
import { useCompaniesStore } from 'dashboard/stores/companies';
import { useToggle } from '@vueuse/core';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  selectedCompanyName: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['change']);
const companyId = defineModel({
  type: [Number, String],
  default: null,
});

const { t } = useI18n();
const companiesStore = useCompaniesStore();

const [showCompanyDropdown, toggleCompanyDropdown] = useToggle();

const searchQuery = ref('');
const isSearching = ref(false);

const companies = computed(() => companiesStore.getCompaniesList || []);
const isLoading = computed(() => companiesStore.uiFlags.fetchingList);

const clearOption = computed(() => ({
  label: t('DROPDOWN_MENU.CLEAR_SELECTION'),
  value: 'clear',
  action: 'clear',
}));

const companyOptions = computed(() =>
  companies.value.map(company => ({
    label: company.name,
    value: company.id,
    action: 'select',
    isSelected: companyId.value === company.id,
  }))
);

const menuItems = computed(() => {
  const items = [];
  // Show clear option if a company is selected (either by ID or by name prop)
  if (companyId.value || props.selectedCompanyName) {
    items.push(clearOption.value);
  }
  // Add company options after clear option
  items.push(...companyOptions.value);
  return items;
});

const selectedCompany = computed(() => {
  return companies.value.find(company => company.id === companyId.value);
});

const buttonLabel = computed(() => {
  if (selectedCompany.value) {
    return selectedCompany.value.name;
  }
  if (props.selectedCompanyName) {
    return props.selectedCompanyName;
  }
  return props.placeholder;
});

const fetchCompanies = async (search = '') => {
  if (!search) return;
  isSearching.value = true;
  try {
    await companiesStore.search({
      search,
      page: 1,
      sort: 'name',
    });
  } finally {
    isSearching.value = false;
  }
};

const debouncedSearch = debounce(query => {
  searchQuery.value = query;
  fetchCompanies(query);
}, 300);

const handleAction = ({ value, action }) => {
  if (action === 'clear') {
    companyId.value = null;
    emit('change', null);
    toggleCompanyDropdown(false);
    return;
  }

  if (companyId.value === value) {
    companyId.value = null;
    emit('change', null);
  } else {
    companyId.value = value;
    const company = companies.value.find(c => c.id === value);
    emit('change', company);
  }
  toggleCompanyDropdown(false);
};

const handleSearch = query => {
  debouncedSearch(query);
};

const handleClickOutside = () => {
  toggleCompanyDropdown(false);
};

watch(showCompanyDropdown, isOpen => {
  if (!isOpen) {
    searchQuery.value = '';
    companiesStore.clearRecords();
  }
});
</script>

<template>
  <div v-on-click-outside="handleClickOutside" class="relative w-full min-w-0">
    <Button
      slate
      sm
      :label="buttonLabel"
      no-animation
      type="button"
      :variant="showCompanyDropdown ? 'faded' : 'solid'"
      icon="i-lucide-briefcase-business"
      justify="start"
      class="w-full -outline-offset-1"
      @click="toggleCompanyDropdown()"
    />

    <Transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <DropdownMenu
        v-if="showCompanyDropdown"
        :menu-items="menuItems"
        show-search
        disable-local-filtering
        :search-placeholder="t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')"
        :empty-state-message="t('COMPANIES.DROPDOWN_MENU.EMPTY_STATE')"
        :is-loading="isLoading"
        :is-searching="isSearching"
        class="max-h-60 overflow-y-auto absolute z-50 w-full mt-1 top-full"
        @action="handleAction"
        @search="handleSearch"
      />
    </Transition>
  </div>
</template>
