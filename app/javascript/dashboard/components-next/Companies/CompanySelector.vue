<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import CompanyAPI from 'dashboard/api/companies';
import { useAlert } from 'dashboard/composables';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: '',
  },
  // Name of the linked company, so the label shows before the list is loaded.
  selectedName: {
    type: String,
    default: '',
  },
  isDetailsView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const CREATE_PREFIX = 'create:';

const options = ref([]);
const searchQuery = ref('');

const toOption = company => ({ label: company.name, value: company.id });

const createOption = computed(() => {
  const name = searchQuery.value.trim();
  if (!name) return null;

  const exists = options.value.some(
    option => option.label.toLowerCase() === name.toLowerCase()
  );
  if (exists) return null;

  return {
    label: t('COMPANIES.SELECTOR.CREATE_OPTION', { name }),
    value: `${CREATE_PREFIX}${name}`,
  };
});

const comboboxOptions = computed(() => {
  const list = [...options.value];

  // Keep the linked company visible even when it is not in the loaded results.
  if (
    props.modelValue &&
    props.selectedName &&
    !list.some(option => option.value === Number(props.modelValue))
  ) {
    list.unshift({
      label: props.selectedName,
      value: Number(props.modelValue),
    });
  }

  if (createOption.value) list.push(createOption.value);
  return list;
});

const fetchCompanies = async query => {
  try {
    const {
      data: { payload },
    } = query
      ? await CompanyAPI.search(query)
      : await CompanyAPI.get({ page: 1 });
    options.value = (payload || []).map(toOption);
  } catch {
    options.value = [];
  }
};

// Fetch lazily, only when the dropdown opens, instead of on mount.
const handleOpen = () => {
  searchQuery.value = '';
  fetchCompanies('');
};

const handleSearch = useDebounceFn(query => {
  searchQuery.value = query?.trim() || '';
  fetchCompanies(searchQuery.value);
}, 300);

const createCompany = async name => {
  try {
    const {
      data: { payload },
    } = await CompanyAPI.create({ company: { name } });
    emit('select', { id: payload.id, name: payload.name });
    useAlert(t('COMPANIES.CREATE.MESSAGES.SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.CREATE.MESSAGES.ERROR'));
  }
};

const handleSelect = value => {
  if (typeof value === 'string' && value.startsWith(CREATE_PREFIX)) {
    createCompany(value.slice(CREATE_PREFIX.length));
    return;
  }

  const id = value ? Number(value) : '';
  const selected = comboboxOptions.value.find(option => option.value === id);
  emit('select', { id, name: selected?.label || '' });
};
</script>

<template>
  <ComboBox
    :model-value="modelValue"
    :options="comboboxOptions"
    :display-label="selectedName"
    :placeholder="t('COMPANIES.SELECTOR.PLACEHOLDER')"
    :search-placeholder="t('COMPANIES.SEARCH_PLACEHOLDER')"
    use-api-results
    class="[&>div>button]:h-8 [&>div>div_ul]:max-h-56"
    :class="{
      '[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:!outline-transparent':
        !isDetailsView,
      '[&>div>button]:!bg-n-alpha-black2': isDetailsView,
    }"
    @open="handleOpen"
    @search="handleSearch"
    @update:model-value="handleSelect"
  />
</template>
