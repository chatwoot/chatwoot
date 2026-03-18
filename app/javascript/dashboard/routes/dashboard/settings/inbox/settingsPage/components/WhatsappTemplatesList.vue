<script setup>
import { computed, defineEmits, defineProps, ref, watch, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappTemplatePreviewModal from './WhatsappTemplatePreviewModal.vue';
import { getWhatsAppLanguageName } from '../whatsappLanguages.js';

const props = defineProps({
  templates: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  deletingTemplateName: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['delete']);
const { t } = useI18n();

// Modal state
const showPreviewModal = ref(false);
const selectedTemplate = ref(null);

// Pagination and search state
const searchQuery = ref('');
const selectedCategories = ref([]);
const selectedStatuses = ref([]);
const selectedLanguages = ref([]);
const currentPage = ref(1);
const itemsPerPage = 10;

// Dropdown visibility state
const showCategoryDropdown = ref(false);
const showStatusDropdown = ref(false);
const showLanguageDropdown = ref(false);
const categoryDropdownRef = ref(null);
const statusDropdownRef = ref(null);
const languageDropdownRef = ref(null);

// Category options for filter
const categoryOptions = computed(() => [
  { value: 'MARKETING', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.MARKETING'), icon: 'i-lucide-megaphone', class: 'text-n-violet-10' },
  { value: 'UTILITY', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.UTILITY'), icon: 'i-lucide-wrench', class: 'text-n-blue-10' },
  { value: 'AUTHENTICATION', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.AUTHENTICATION'), icon: 'i-lucide-shield-check', class: 'text-n-teal-10' },
]);

// Status options for filter (based on Meta WhatsApp API statuses)
const statusOptions = computed(() => [
  { value: 'APPROVED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.APPROVED'), icon: 'i-lucide-circle-check', class: 'text-n-teal-11' },
  { value: 'PENDING', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING'), icon: 'i-lucide-clock', class: 'text-n-amber-11' },
  { value: 'REJECTED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REJECTED'), icon: 'i-lucide-circle-x', class: 'text-n-ruby-10' },
  { value: 'PAUSED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PAUSED'), icon: 'i-lucide-pause-circle', class: 'text-n-slate-10' },
  { value: 'IN_APPEAL', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.IN_APPEAL'), icon: 'i-lucide-message-square-warning', class: 'text-n-orange-10' },
  { value: 'DISABLED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.DISABLED'), icon: 'i-lucide-ban', class: 'text-n-slate-9' },
  { value: 'FLAGGED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.FLAGGED'), icon: 'i-lucide-flag', class: 'text-n-ruby-10' },
  { value: 'PENDING_DELETION', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING_DELETION'), icon: 'i-lucide-trash-2', class: 'text-n-ruby-9' },
  { value: 'REINSTATED', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REINSTATED'), icon: 'i-lucide-rotate-ccw', class: 'text-n-teal-10' },
]);


// Language options extracted from existing templates
const languageOptions = computed(() => {
  const languages = new Set();
  props.templates.forEach(template => {
    if (template.language) {
      languages.add(template.language);
    }
  });
  return Array.from(languages).sort().map(lang => ({
    value: lang,
    label: getWhatsAppLanguageName(lang)
  }));
});

// Toggle category selection
const toggleCategory = (category) => {
  const index = selectedCategories.value.indexOf(category);
  if (index === -1) {
    selectedCategories.value.push(category);
  } else {
    selectedCategories.value.splice(index, 1);
  }
};

// Toggle status selection
const toggleStatus = (status) => {
  const index = selectedStatuses.value.indexOf(status);
  if (index === -1) {
    selectedStatuses.value.push(status);
  } else {
    selectedStatuses.value.splice(index, 1);
  }
};

// Toggle language selection
const toggleLanguage = (language) => {
  const index = selectedLanguages.value.indexOf(language);
  if (index === -1) {
    selectedLanguages.value.push(language);
  } else {
    selectedLanguages.value.splice(index, 1);
  }
};

// Select/deselect all categories
const toggleAllCategories = () => {
  if (selectedCategories.value.length === categoryOptions.value.length) {
    selectedCategories.value = [];
  } else {
    selectedCategories.value = categoryOptions.value.map(c => c.value);
  }
};

// Select/deselect all statuses
const toggleAllStatuses = () => {
  if (selectedStatuses.value.length === statusOptions.value.length) {
    selectedStatuses.value = [];
  } else {
    selectedStatuses.value = statusOptions.value.map(s => s.value);
  }
};

// Select/deselect all languages
const toggleAllLanguages = () => {
  if (selectedLanguages.value.length === languageOptions.value.length) {
    selectedLanguages.value = [];
  } else {
    selectedLanguages.value = languageOptions.value.map(l => l.value);
  }
};

// Category dropdown label
const categoryDropdownLabel = computed(() => {
  if (selectedCategories.value.length === 0) {
    return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.ALL_CATEGORIES');
  }
  if (selectedCategories.value.length === 1) {
    const category = categoryOptions.value.find(c => c.value === selectedCategories.value[0]);
    return category?.label || selectedCategories.value[0];
  }
  return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.CATEGORIES_SELECTED', { count: selectedCategories.value.length });
});

// Status dropdown label
const statusDropdownLabel = computed(() => {
  if (selectedStatuses.value.length === 0) {
    return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.ALL_STATUSES');
  }
  if (selectedStatuses.value.length === 1) {
    const status = statusOptions.value.find(s => s.value === selectedStatuses.value[0]);
    return status?.label || selectedStatuses.value[0];
  }
  return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.STATUSES_SELECTED', { count: selectedStatuses.value.length });
});

// Language dropdown label
const languageDropdownLabel = computed(() => {
  if (selectedLanguages.value.length === 0) {
    return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.ALL_LANGUAGES');
  }
  if (selectedLanguages.value.length === 1) {
    return selectedLanguages.value[0];
  }
  return t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.LANGUAGES_SELECTED', { count: selectedLanguages.value.length });
});

// Close dropdowns when clicking outside
const handleClickOutside = (event) => {
  if (categoryDropdownRef.value && !categoryDropdownRef.value.contains(event.target)) {
    showCategoryDropdown.value = false;
  }
  if (statusDropdownRef.value && !statusDropdownRef.value.contains(event.target)) {
    showStatusDropdown.value = false;
  }
  if (languageDropdownRef.value && !languageDropdownRef.value.contains(event.target)) {
    showLanguageDropdown.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

// Reset to first page when filters change
watch([searchQuery, selectedCategories, selectedStatuses, selectedLanguages], () => {
  currentPage.value = 1;
}, { deep: true });

// Filtered templates based on search, category, status and language
const filteredTemplates = computed(() => {
  let result = props.templates;

  // Filter by category (multi-select)
  if (selectedCategories.value.length > 0) {
    result = result.filter(
      template => selectedCategories.value.includes(template.category)
    );
  }

  // Filter by status (multi-select)
  if (selectedStatuses.value.length > 0) {
    result = result.filter(
      template => selectedStatuses.value.includes(template.status)
    );
  }

  // Filter by language (multi-select)
  if (selectedLanguages.value.length > 0) {
    result = result.filter(
      template => selectedLanguages.value.includes(template.language)
    );
  }

  // Filter by search query (name only)
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      template => template.name?.toLowerCase().includes(query)
    );
  }

  return result;
});

// Sorted templates
const sortedTemplates = computed(() => {
  return [...filteredTemplates.value].sort((a, b) => {
    const statusOrder = { APPROVED: 0, PENDING: 1, REJECTED: 2 };
    const statusDiff =
      (statusOrder[a.status] || 3) - (statusOrder[b.status] || 3);
    if (statusDiff !== 0) return statusDiff;
    return a.name.localeCompare(b.name);
  });
});

// Pagination computed
const totalPages = computed(() =>
  Math.ceil(sortedTemplates.value.length / itemsPerPage)
);

const paginatedTemplates = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return sortedTemplates.value.slice(start, end);
});

const showingFrom = computed(() =>
  sortedTemplates.value.length === 0
    ? 0
    : (currentPage.value - 1) * itemsPerPage + 1
);

const showingTo = computed(() =>
  Math.min(currentPage.value * itemsPerPage, sortedTemplates.value.length)
);

// Check if any filter is active
const hasActiveFilters = computed(() => {
  return searchQuery.value.trim() || selectedCategories.value.length > 0 || selectedStatuses.value.length > 0 || selectedLanguages.value.length > 0;
});

// Page numbers to show
const visiblePages = computed(() => {
  const pages = [];
  const total = totalPages.value;
  const current = currentPage.value;

  if (total <= 7) {
    for (let i = 1; i <= total; i++) pages.push(i);
  } else {
    if (current <= 3) {
      pages.push(1, 2, 3, 4, '...', total);
    } else if (current >= total - 2) {
      pages.push(1, '...', total - 3, total - 2, total - 1, total);
    } else {
      pages.push(1, '...', current - 1, current, current + 1, '...', total);
    }
  }

  return pages;
});

const getStatusConfig = status => {
  const configs = {
    APPROVED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.APPROVED'),
      icon: 'i-lucide-circle-check',
      class: 'text-n-teal-11 bg-n-teal-3',
    },
    PENDING: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING'),
      icon: 'i-lucide-clock',
      class: 'text-n-amber-11 bg-n-amber-3',
    },
    REJECTED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REJECTED'),
      icon: 'i-lucide-circle-x',
      class: 'text-n-ruby-10 bg-n-ruby-3',
    },
    PAUSED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PAUSED'),
      icon: 'i-lucide-pause-circle',
      class: 'text-n-slate-10 bg-n-slate-3',
    },
    IN_APPEAL: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.IN_APPEAL'),
      icon: 'i-lucide-message-square-warning',
      class: 'text-n-orange-10 bg-n-orange-3',
    },
    DISABLED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.DISABLED'),
      icon: 'i-lucide-ban',
      class: 'text-n-slate-9 bg-n-slate-3',
    },
    FLAGGED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.FLAGGED'),
      icon: 'i-lucide-flag',
      class: 'text-n-ruby-10 bg-n-ruby-3',
    },
    PENDING_DELETION: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING_DELETION'),
      icon: 'i-lucide-trash-2',
      class: 'text-n-ruby-9 bg-n-ruby-3',
    },
    REINSTATED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REINSTATED'),
      icon: 'i-lucide-rotate-ccw',
      class: 'text-n-teal-10 bg-n-teal-3',
    },
  };

  return (
    configs[status] || {
      label: status,
      icon: 'i-lucide-help-circle',
      class: 'text-n-slate-11 bg-n-slate-3',
    }
  );
};

const getCategoryLabel = category => {
  const labels = {
    MARKETING: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.MARKETING'),
    UTILITY: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.UTILITY'),
    AUTHENTICATION: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.AUTHENTICATION'),
  };
  return labels[category] || category;
};

const getHeaderFormat = template => {
  const headerComponent = template.components?.find(c => c.type === 'HEADER');
  return headerComponent?.format || null;
};

const getBodyText = template => {
  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  return bodyComponent?.text || '';
};

// Statuses that prevent deletion (under review by Meta)
const PENDING_REVIEW_STATUSES = ['PENDING', 'IN_APPEAL'];

const isTemplateUnderReview = (template) => {
  return PENDING_REVIEW_STATUSES.includes(template.status);
};

// Delete confirmation state
const showDeleteConfirmation = ref(false);
const templateToDelete = ref(null);

const openDeleteConfirmation = (template) => {
  templateToDelete.value = template;
  showDeleteConfirmation.value = true;
};

const closeDeleteConfirmation = () => {
  showDeleteConfirmation.value = false;
  templateToDelete.value = null;
};

const confirmDelete = () => {
  if (templateToDelete.value) {
    emit('delete', {
      name: templateToDelete.value.name,
      id: templateToDelete.value.id,
    });
  }
  closeDeleteConfirmation();
};

const deleteMessageValue = computed(() => {
  return templateToDelete.value ? ` ${templateToDelete.value.name}?` : '';
});

const clearFilters = () => {
  searchQuery.value = '';
  selectedCategories.value = [];
  selectedStatuses.value = [];
  selectedLanguages.value = [];
};

const goToPage = page => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
  }
};

// Modal handlers
const openTemplatePreview = template => {
  selectedTemplate.value = template;
  showPreviewModal.value = true;
};

const closePreviewModal = () => {
  showPreviewModal.value = false;
  selectedTemplate.value = null;
};

const handleDeleteFromModal = (template) => {
  closePreviewModal();
  openDeleteConfirmation(template);
};
</script>

<template>
  <div>
    <!-- Search and Filter Bar -->
    <div class="flex flex-col gap-3 mb-4">
      <!-- First row: Search -->
      <div class="flex items-center gap-2 px-3 h-10 rounded-lg bg-n-alpha-2 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand transition-all duration-200">
        <Icon icon="i-lucide-search" class="size-4 text-n-slate-10 flex-shrink-0" />
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.SEARCH_PLACEHOLDER')"
          class="search-input w-full mb-0 text-sm bg-inherit text-n-slate-12 placeholder:text-n-slate-10"
        />
        <button
          v-if="searchQuery"
          class="flex-shrink-0"
          @click="searchQuery = ''"
        >
          <Icon icon="i-lucide-x" class="size-4 text-n-slate-9 hover:text-n-slate-11" />
        </button>
      </div>

      <!-- Second row: Filters -->
      <div class="flex flex-wrap gap-3">
        <!-- Category Multi-Select Dropdown -->
        <div ref="categoryDropdownRef" class="relative w-44">
          <button
            type="button"
            class="w-full h-10 px-3 pr-8 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 text-n-slate-12 cursor-pointer transition-all duration-200 text-left select-arrow"
            :class="{ 'outline-n-brand': showCategoryDropdown }"
            @click.stop="showCategoryDropdown = !showCategoryDropdown; showStatusDropdown = false; showLanguageDropdown = false"
          >
            <span class="truncate block">{{ categoryDropdownLabel }}</span>
          </button>

          <!-- Category Dropdown Menu -->
          <div
            v-if="showCategoryDropdown"
            class="absolute z-50 mt-1 w-52 py-1 rounded-lg bg-n-solid-2 border border-n-weak shadow-lg"
          >
            <!-- Select All -->
            <label
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedCategories.length === categoryOptions.length"
                :indeterminate="selectedCategories.length > 0 && selectedCategories.length < categoryOptions.length"
                class="checkbox-custom"
                @change="toggleAllCategories"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.SELECT_ALL') }}
              </span>
            </label>

            <div class="border-t border-n-weak my-1"></div>

            <!-- Category Options -->
            <label
              v-for="option in categoryOptions"
              :key="option.value"
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedCategories.includes(option.value)"
                class="checkbox-custom"
                @change="toggleCategory(option.value)"
              />
              <Icon :icon="option.icon" :class="['size-4', option.class]" />
              <span class="text-sm text-n-slate-12">{{ option.label }}</span>
            </label>
          </div>
        </div>

        <!-- Status Multi-Select Dropdown -->
        <div ref="statusDropdownRef" class="relative w-44">
          <button
            type="button"
            class="w-full h-10 px-3 pr-8 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 text-n-slate-12 cursor-pointer transition-all duration-200 text-left select-arrow"
            :class="{ 'outline-n-brand': showStatusDropdown }"
            @click.stop="showStatusDropdown = !showStatusDropdown; showCategoryDropdown = false; showLanguageDropdown = false"
          >
            <span class="truncate block">{{ statusDropdownLabel }}</span>
          </button>

          <!-- Status Dropdown Menu -->
          <div
            v-if="showStatusDropdown"
            class="absolute z-50 mt-1 w-56 py-1 rounded-lg bg-n-solid-2 border border-n-weak shadow-lg max-h-72 overflow-y-auto"
          >
            <!-- Select All -->
            <label
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedStatuses.length === statusOptions.length"
                :indeterminate="selectedStatuses.length > 0 && selectedStatuses.length < statusOptions.length"
                class="checkbox-custom"
                @change="toggleAllStatuses"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.SELECT_ALL') }}
              </span>
            </label>

            <div class="border-t border-n-weak my-1"></div>

            <!-- Status Options -->
            <label
              v-for="option in statusOptions"
              :key="option.value"
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedStatuses.includes(option.value)"
                class="checkbox-custom"
                @change="toggleStatus(option.value)"
              />
              <Icon :icon="option.icon" :class="['size-4', option.class]" />
              <span class="text-sm text-n-slate-12">{{ option.label }}</span>
            </label>
          </div>
        </div>

        <!-- Language Multi-Select Dropdown -->
        <div v-if="languageOptions.length > 0" ref="languageDropdownRef" class="relative w-40">
          <button
            type="button"
            class="w-full h-10 px-3 pr-8 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 text-n-slate-12 cursor-pointer transition-all duration-200 text-left select-arrow"
            :class="{ 'outline-n-brand': showLanguageDropdown }"
            @click.stop="showLanguageDropdown = !showLanguageDropdown; showCategoryDropdown = false; showStatusDropdown = false"
          >
            <span class="truncate block">{{ languageDropdownLabel }}</span>
          </button>

          <!-- Language Dropdown Menu -->
          <div
            v-if="showLanguageDropdown"
            class="absolute z-50 mt-1 w-48 py-1 rounded-lg bg-n-solid-2 border border-n-weak shadow-lg max-h-60 overflow-y-auto"
          >
            <!-- Select All -->
            <label
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedLanguages.length === languageOptions.length"
                :indeterminate="selectedLanguages.length > 0 && selectedLanguages.length < languageOptions.length"
                class="checkbox-custom"
                @change="toggleAllLanguages"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.SELECT_ALL') }}
              </span>
            </label>

            <div class="border-t border-n-weak my-1"></div>

            <!-- Language Options -->
            <label
              v-for="option in languageOptions"
              :key="option.value"
              class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2"
              @click.stop
            >
              <input
                type="checkbox"
                :checked="selectedLanguages.includes(option.value)"
                class="checkbox-custom"
                @change="toggleLanguage(option.value)"
              />
              <Icon icon="i-lucide-globe" class="size-4 text-n-slate-10" />
              <span class="text-sm text-n-slate-12">{{ option.label }}</span>
            </label>
          </div>
        </div>

        <!-- Clear Filters Button -->
        <button
          v-if="hasActiveFilters"
          class="h-10 px-3 text-sm rounded-lg text-n-brand hover:bg-n-alpha-2 transition-colors flex items-center gap-1"
          @click="clearFilters"
        >
          <Icon icon="i-lucide-x" class="size-4" />
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.CLEAR_FILTERS') }}
        </button>
      </div>
    </div>

    <!-- Results count and template limit -->
    <div
      v-if="templates.length > 0"
      class="flex items-center justify-between mb-3 text-sm text-n-slate-11"
    >
      <div class="flex items-center gap-4">
        <span>
          {{
            $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.SHOWING', {
              from: showingFrom,
              to: showingTo,
              total: sortedTemplates.length,
            })
          }}
        </span>
        <span v-if="hasActiveFilters && filteredTemplates.length !== templates.length">
          {{
            $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.FILTERED', {
              count: filteredTemplates.length,
              total: templates.length,
            })
          }}
        </span>
      </div>
      <!-- Template limit indicator -->
      <span class="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-n-alpha-2 text-xs font-medium">
        <Icon icon="i-lucide-layers" class="size-3.5" />
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.TEMPLATE_LIMIT', { count: templates.length }) }}
      </span>
    </div>

    <!-- Templates List -->
    <div v-if="paginatedTemplates.length > 0" class="space-y-3">
      <div
        v-for="template in paginatedTemplates"
        :key="template.id || template.name"
        class="p-4 rounded-xl border transition-colors bg-n-alpha-1 border-n-weak hover:border-n-slate-6 cursor-pointer"
        @click="openTemplatePreview(template)"
      >
        <div class="flex gap-4 justify-between items-start">
          <!-- Template Info -->
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap gap-2 items-center mb-2">
              <h4 class="text-base font-semibold text-n-slate-12">
                {{ template.name }}
              </h4>
              <!-- Status Badge -->
              <span
                :class="[
                  getStatusConfig(template.status).class,
                  'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium',
                ]"
              >
                <Icon
                  :icon="getStatusConfig(template.status).icon"
                  class="size-3"
                />
                {{ getStatusConfig(template.status).label }}
              </span>
            </div>

            <!-- Template Details -->
            <div class="flex flex-wrap gap-4 text-sm text-n-slate-11">
              <span class="flex gap-1 items-center">
                <Icon icon="i-lucide-tag" class="size-3.5" />
                {{ getCategoryLabel(template.category) }}
              </span>
              <span class="flex gap-1 items-center">
                <Icon icon="i-lucide-globe" class="size-3.5" />
                {{ getWhatsAppLanguageName(template.language) }}
              </span>
              <span
                v-if="getHeaderFormat(template)"
                class="flex gap-1 items-center"
              >
                <Icon icon="i-lucide-image" class="size-3.5" />
                {{ getHeaderFormat(template) }}
              </span>
            </div>

            <!-- Body Preview -->
            <p
              v-if="getBodyText(template)"
              class="mt-2 text-sm truncate text-n-slate-11"
            >
              {{ getBodyText(template) }}
            </p>
          </div>

          <!-- Actions -->
          <div class="flex gap-2 items-center shrink-0">
            <div
              v-tooltip="isTemplateUnderReview(template) ? $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_UNDER_REVIEW') : null"
            >
              <NextButton
                faded
                ruby
                sm
                icon="i-lucide-trash-2"
                :is-loading="props.deletingTemplateName === template.name"
                :disabled="isLoading || isTemplateUnderReview(template)"
                @click.stop="openDeleteConfirmation(template)"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state for filters -->
    <div
      v-else-if="hasActiveFilters && templates.length > 0"
      class="py-12 text-center"
    >
      <Icon
        icon="i-lucide-search-x"
        class="mx-auto mb-3 size-12 text-n-slate-9"
      />
      <p class="text-n-slate-11">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.NO_RESULTS') }}
      </p>
      <button
        class="mt-2 text-sm text-n-brand hover:underline"
        @click="clearFilters"
      >
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LIST.CLEAR_SEARCH') }}
      </button>
    </div>

    <!-- Pagination -->
    <div
      v-if="totalPages > 1"
      class="flex items-center justify-center gap-1 mt-6"
    >
      <!-- Previous button -->
      <button
        class="p-2 rounded-lg hover:bg-n-slate-3 disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === 1"
        @click="goToPage(currentPage - 1)"
      >
        <Icon icon="i-lucide-chevron-left" class="size-4 text-n-slate-11" />
      </button>

      <!-- Page numbers -->
      <template v-for="page in visiblePages" :key="page">
        <span v-if="page === '...'" class="px-2 text-n-slate-9">...</span>
        <button
          v-else
          class="min-w-[36px] h-9 px-3 rounded-lg text-sm font-medium transition-colors"
          :class="
            page === currentPage
              ? 'bg-n-brand text-white'
              : 'hover:bg-n-slate-3 text-n-slate-11'
          "
          @click="goToPage(page)"
        >
          {{ page }}
        </button>
      </template>

      <!-- Next button -->
      <button
        class="p-2 rounded-lg hover:bg-n-slate-3 disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === totalPages"
        @click="goToPage(currentPage + 1)"
      >
        <Icon icon="i-lucide-chevron-right" class="size-4 text-n-slate-11" />
      </button>
    </div>

    <!-- Template Preview Modal -->
    <WhatsappTemplatePreviewModal
      :show="showPreviewModal"
      :template="selectedTemplate"
      @close="closePreviewModal"
      @delete="handleDeleteFromModal"
    />

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-model:show="showDeleteConfirmation"
      :on-close="closeDeleteConfirmation"
      :on-confirm="confirmDelete"
      :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE.CONFIRM.TITLE')"
      :message="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessageValue"
      :confirm-text="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE.CONFIRM.YES')"
      :reject-text="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE.CONFIRM.NO')"
    />
  </div>
</template>

<style scoped>
.search-input {
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
  background-color: transparent !important;
  background: transparent !important;
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  padding: 0 !important;
  margin: 0 !important;
  height: auto !important;
  line-height: normal !important;
}

.search-input:focus {
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
}

.select-arrow {
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2'><path d='M6 9l6 6 6-6'/></svg>");
  background-repeat: no-repeat;
  background-position: right 0.5rem center;
  background-size: 16px 16px;
}

.checkbox-custom {
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  border: 2px solid var(--n-slate-7);
  border-radius: 4px;
  background-color: transparent;
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
}

.checkbox-custom:checked {
  background-color: var(--n-brand);
  border-color: var(--n-brand);
}

.checkbox-custom:checked::after {
  content: '';
  position: absolute;
  left: 4px;
  top: 1px;
  width: 4px;
  height: 8px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

.checkbox-custom:indeterminate {
  background-color: var(--n-brand);
  border-color: var(--n-brand);
}

.checkbox-custom:indeterminate::after {
  content: '';
  position: absolute;
  left: 2px;
  top: 5px;
  width: 8px;
  height: 2px;
  background: white;
}

.checkbox-custom:hover {
  border-color: var(--n-slate-9);
}

.checkbox-custom:checked:hover,
.checkbox-custom:indeterminate:hover {
  background-color: var(--n-brand);
  border-color: var(--n-brand);
}
</style>
