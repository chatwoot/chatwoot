<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

import KnowledgeBaseLayout from 'dashboard/components-next/KnowledgeBase/KnowledgeBaseLayout.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// Sample data for empty state preview
const sampleCategories = [
  {
    id: 1,
    name: 'Envíos y Entregas',
    description: 'Preguntas sobre tiempos y costos de envío',
    faqs: [
      { id: 1, question: '¿Cuánto tiempo tarda en llegar mi pedido?' },
      { id: 2, question: '¿Cuál es el costo de envío?' },
    ],
  },
  {
    id: 2,
    name: 'Pagos y Facturación',
    description: 'Métodos de pago y facturas',
    faqs: [
      { id: 3, question: '¿Qué métodos de pago aceptan?' },
      { id: 4, question: '¿Cómo solicito mi factura?' },
    ],
  },
  {
    id: 3,
    name: 'Devoluciones',
    description: 'Políticas de devolución y cambios',
    faqs: [
      { id: 5, question: '¿Cómo puedo devolver un producto?' },
    ],
  },
];

const { t, locale } = useI18n();
const store = useStore();

// Get default display language from site locale, fallback to 'en'
const getDefaultDisplayLanguage = () => {
  const siteLocale = locale.value;
  // Only support 'es' and 'en' for FAQ display
  if (siteLocale === 'es' || siteLocale === 'en') {
    return siteLocale;
  }
  return 'en'; // Fallback to English
};

// UI State
const showCategoryForm = ref(false);
const showFaqForm = ref(false);
const showDeleteModal = ref(false);

const editingCategory = ref(null);
const editingFaq = ref(null);
const itemToDelete = ref(null);
const deleteType = ref(null);
const expandedCategories = ref(new Set());
const expandedFaqs = ref(new Set());
const activeLanguage = ref('es');
const displayLanguage = ref(getDefaultDisplayLanguage());

// Search and pagination state
const searchQuery = ref('');
const isSearching = ref(false);
const searchDebounceTimer = ref(null);

// Form data
const categoryForm = ref({ name: '', description: '', parent_id: null });
const faqForm = ref({
  faq_category_id: null,
  translations: {
    es: { question: '', answer: '' },
    en: { question: '', answer: '' },
  },
});

// Getters
const categories = computed(() => store.getters['faqCategories/getTree']);
const faqItems = computed(() => store.getters['faqItems/getFaqItems']);
const meta = computed(() => store.getters['faqCategories/getMeta']);
const uiFlagsCategories = computed(() => store.getters['faqCategories/getUIFlags']);
const uiFlagsItems = computed(() => store.getters['faqItems/getUIFlags']);

const isLoading = computed(() => uiFlagsCategories.value.isFetchingTree);
const isFetchingItems = computed(() => uiFlagsItems.value.isFetching);
const isSaving = computed(() =>
  uiFlagsCategories.value.isCreating ||
  uiFlagsCategories.value.isUpdating ||
  uiFlagsItems.value.isCreating ||
  uiFlagsItems.value.isUpdating
);
const isDeleting = computed(() =>
  uiFlagsCategories.value.isDeleting || uiFlagsItems.value.isDeleting
);

const isEmpty = computed(() => !isLoading.value && categories.value.length === 0 && !searchQuery.value);

// Computed getters/setters for translation form fields (fixes reactivity with dynamic keys)
const currentQuestion = computed({
  get: () => faqForm.value.translations[activeLanguage.value]?.question || '',
  set: (val) => {
    if (!faqForm.value.translations[activeLanguage.value]) {
      faqForm.value.translations[activeLanguage.value] = { question: '', answer: '' };
    }
    faqForm.value.translations[activeLanguage.value].question = val;
  },
});

const currentAnswer = computed({
  get: () => faqForm.value.translations[activeLanguage.value]?.answer || '',
  set: (val) => {
    if (!faqForm.value.translations[activeLanguage.value]) {
      faqForm.value.translations[activeLanguage.value] = { question: '', answer: '' };
    }
    faqForm.value.translations[activeLanguage.value].answer = val;
  },
});

// Get FAQ question/answer based on display language
const getFaqQuestion = (faq) => {
  const translations = faq.translations || {};
  return translations[displayLanguage.value]?.question || translations.es?.question || translations.en?.question || '';
};

const getFaqAnswer = (faq) => {
  const translations = faq.translations || {};
  return translations[displayLanguage.value]?.answer || translations.es?.answer || translations.en?.answer || '';
};

// Flat list for dropdown
const flatCategories = computed(() => {
  const result = [];
  const flatten = (items, level = 0) => {
    items.forEach(item => {
      result.push({ ...item, level });
      if (item.children?.length) flatten(item.children, level + 1);
    });
  };
  flatten(categories.value);
  return result;
});

// Pagination computed
const visiblePages = computed(() => {
  const current = meta.value?.current_page || 1;
  const total = meta.value?.total_pages || 1;
  const pages = [];

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      pages.push(i);
    }
  } else {
    pages.push(1);
    if (current <= 3) {
      for (let i = 2; i <= 5; i++) {
        pages.push(i);
      }
      pages.push('ellipsis1');
      pages.push(total);
    } else if (current >= total - 2) {
      pages.push('ellipsis1');
      for (let i = total - 4; i <= total; i++) {
        pages.push(i);
      }
    } else {
      pages.push('ellipsis1');
      pages.push(current - 1);
      pages.push(current);
      pages.push(current + 1);
      pages.push('ellipsis2');
      pages.push(total);
    }
  }
  return pages;
});

// Methods
const fetchData = async () => {
  await Promise.all([
    store.dispatch('faqCategories/get'),
    store.dispatch('faqCategories/getTree', { page: 1, per_page: 5 }),
    store.dispatch('faqItems/get', { page: 1, per_page: 500 }),
  ]);
};

// Helper to refresh data maintaining current search and pagination
const refreshData = async () => {
  const currentPage = meta.value?.current_page || 1;
  await Promise.all([
    store.dispatch('faqCategories/get'),
    store.dispatch('faqCategories/getTree', {
      page: currentPage,
      per_page: 5,
      q: searchQuery.value || undefined,
    }),
    store.dispatch('faqItems/get', { page: 1, per_page: 500 }),
  ]);
};

// Search functions
const executeSearch = async (query) => {
  if (isSearching.value) return;
  isSearching.value = true;
  try {
    await store.dispatch('faqCategories/getTree', {
      page: 1,
      per_page: 5,
      q: query || undefined
    });
  } finally {
    isSearching.value = false;
  }
};

const performSearch = (query) => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
  searchDebounceTimer.value = setTimeout(() => {
    executeSearch(query);
    searchDebounceTimer.value = null;
  }, 1500);
};

const handleSearchEnter = () => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
    searchDebounceTimer.value = null;
  }
  executeSearch(searchQuery.value);
};

watch(searchQuery, (newQuery) => {
  performSearch(newQuery);
});

// Pagination
const handlePageChange = async (page) => {
  const totalPages = meta.value?.total_pages || 1;
  const currentPage = meta.value?.current_page || 1;
  if (page < 1 || page > totalPages || page === currentPage) {
    return;
  }
  await store.dispatch('faqCategories/getTree', {
    page,
    per_page: 5,
    q: searchQuery.value || undefined
  });
};

const toggleExpand = (categoryId) => {
  if (expandedCategories.value.has(categoryId)) {
    expandedCategories.value.delete(categoryId);
  } else {
    expandedCategories.value.add(categoryId);
  }
};

const isExpanded = (categoryId) => expandedCategories.value.has(categoryId);

const toggleFaqExpand = (faqId) => {
  if (expandedFaqs.value.has(faqId)) {
    expandedFaqs.value.delete(faqId);
  } else {
    expandedFaqs.value.add(faqId);
  }
};

const isFaqExpanded = (faqId) => expandedFaqs.value.has(faqId);

const getFaqsForCategory = (categoryId) => {
  return faqItems.value
    .filter(faq => {
      if (faq.faq_category_id !== categoryId) return false;
      // Filter by display language - only show FAQs that have content in selected language
      const translations = faq.translations || {};
      const langContent = translations[displayLanguage.value];
      return langContent?.question || langContent?.answer;
    })
    .sort((a, b) => a.position - b.position);
};

// Category actions
const openNewCategory = (parentId = null) => {
  editingCategory.value = null;
  categoryForm.value = { name: '', description: '', parent_id: parentId };
  showCategoryForm.value = true;
  showFaqForm.value = false;
};

const openEditCategory = (category) => {
  editingCategory.value = category;
  categoryForm.value = {
    name: category.name,
    description: category.description || '',
    parent_id: category.parent_id,
  };
  showCategoryForm.value = true;
  showFaqForm.value = false;
};

const saveCategory = async () => {
  try {
    if (editingCategory.value) {
      await store.dispatch('faqCategories/update', {
        id: editingCategory.value.id,
        ...categoryForm.value,
      });
      useAlert(t('KNOWLEDGE_BASE.FAQ.CATEGORIES.UPDATE_SUCCESS'));
    } else {
      await store.dispatch('faqCategories/create', categoryForm.value);
      useAlert(t('KNOWLEDGE_BASE.FAQ.CATEGORIES.CREATE_SUCCESS'));
    }
    showCategoryForm.value = false;
    await refreshData();
  } catch (error) {
    if (error.isRateLimited && !editingCategory.value) {
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.RATE_LIMITED', { seconds: error.retryAfter }));
    } else {
      useAlert(t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ERROR'));
    }
  }
};

// FAQ actions
const openNewFaq = (categoryId = null) => {
  editingFaq.value = null;
  faqForm.value = {
    faq_category_id: categoryId,
    translations: {
      es: { question: '', answer: '' },
      en: { question: '', answer: '' },
    },
  };
  activeLanguage.value = 'es';
  showFaqForm.value = true;
  showCategoryForm.value = false;
};

const openEditFaq = (faq) => {
  editingFaq.value = faq;
  const existingTranslations = faq.translations || {};
  faqForm.value = {
    faq_category_id: faq.faq_category_id,
    translations: {
      es: existingTranslations.es || { question: '', answer: '' },
      en: existingTranslations.en || { question: '', answer: '' },
    },
  };
  activeLanguage.value = 'es';
  showFaqForm.value = true;
  showCategoryForm.value = false;
};

const saveFaq = async () => {
  try {
    if (editingFaq.value) {
      await store.dispatch('faqItems/update', {
        id: editingFaq.value.id,
        ...faqForm.value,
      });
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.UPDATE_SUCCESS'));
    } else {
      await store.dispatch('faqItems/create', faqForm.value);
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.CREATE_SUCCESS'));
    }
    showFaqForm.value = false;
    await refreshData();
  } catch (error) {
    if (error.isRateLimited && !editingFaq.value) {
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.RATE_LIMITED', { seconds: error.retryAfter }));
    } else {
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.ERROR'));
    }
  }
};

// Delete
const confirmDelete = (item, type) => {
  itemToDelete.value = item;
  deleteType.value = type;
  showDeleteModal.value = true;
};

const executeDelete = async () => {
  try {
    if (deleteType.value === 'category') {
      await store.dispatch('faqCategories/delete', itemToDelete.value.id);
      useAlert(t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_SUCCESS'));
    } else {
      await store.dispatch('faqItems/delete', itemToDelete.value.id);
      useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE_SUCCESS'));
    }
    showDeleteModal.value = false;
    await refreshData();
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ERROR'));
  }
};

const toggleFaqVisibility = async (faq) => {
  try {
    await store.dispatch('faqItems/toggleVisibility', faq.id);
    useAlert(faq.is_visible
      ? t('KNOWLEDGE_BASE.FAQ.VISIBILITY.HIDDEN')
      : t('KNOWLEDGE_BASE.FAQ.VISIBILITY.SHOWN')
    );
    await refreshData();
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.FAQ.VISIBILITY.ERROR'));
  }
};

const moveFaq = async (faq, direction) => {
  try {
    await store.dispatch('faqItems/move', { itemId: faq.id, direction });
    useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_SUCCESS'));
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_ERROR'));
  }
};

// Check if FAQ can move up (not first in its category)
const canMoveUp = (faq, categoryId) => {
  const faqs = getFaqsForCategory(categoryId);
  const index = faqs.findIndex(f => f.id === faq.id);
  return index > 0;
};

// Check if FAQ can move down (not last in its category)
const canMoveDown = (faq, categoryId) => {
  const faqs = getFaqsForCategory(categoryId);
  const index = faqs.findIndex(f => f.id === faq.id);
  return index < faqs.length - 1;
};

// Marquee animation with constant speed (50px/s)
const SCROLL_SPEED = 50; // pixels per second
const WAIT_START = 4000; // ms to wait at start
const WAIT_END = 6000; // ms to wait at end

const activeMarquees = new Map(); // Track active animations

const startMarquee = (event) => {
  const container = event.currentTarget;
  const text = container.querySelector('.marquee-text');
  if (!text) return;

  // Cancel any existing animation for this element
  const existingTimeout = activeMarquees.get(text);
  if (existingTimeout) {
    clearTimeout(existingTimeout.startTimeout);
    clearTimeout(existingTimeout.endTimeout);
    clearTimeout(existingTimeout.resetTimeout);
  }

  const textWidth = text.scrollWidth;
  const containerWidth = container.offsetWidth;
  const scrollDistance = textWidth - containerWidth;

  if (scrollDistance <= 0) return; // No need to scroll

  const scrollDuration = (scrollDistance / SCROLL_SPEED) * 1000; // Convert to ms

  // Reset position and remove transition
  text.style.transition = 'none';
  text.style.transform = 'translateX(0)';

  // Force reflow
  text.offsetHeight;

  const runAnimation = () => {
    // After WAIT_START, start scrolling
    const startTimeout = setTimeout(() => {
      text.style.transition = `transform ${scrollDuration}ms linear`;
      text.style.transform = `translateX(-${scrollDistance}px)`;

      // After scroll completes, wait WAIT_END then reset
      const endTimeout = setTimeout(() => {
        const resetTimeout = setTimeout(() => {
          // Reset and restart the animation cycle
          text.style.transition = 'none';
          text.style.transform = 'translateX(0)';
          text.offsetHeight; // Force reflow
          runAnimation();
        }, WAIT_END);

        activeMarquees.set(text, { startTimeout: null, endTimeout: null, resetTimeout });
      }, scrollDuration);

      activeMarquees.set(text, { startTimeout: null, endTimeout, resetTimeout: null });
    }, WAIT_START);

    activeMarquees.set(text, { startTimeout, endTimeout: null, resetTimeout: null });
  };

  runAnimation();
};

const stopMarquee = (event) => {
  const container = event.currentTarget;
  const text = container.querySelector('.marquee-text');
  if (!text) return;

  // Cancel any pending timeouts
  const timeouts = activeMarquees.get(text);
  if (timeouts) {
    clearTimeout(timeouts.startTimeout);
    clearTimeout(timeouts.endTimeout);
    clearTimeout(timeouts.resetTimeout);
    activeMarquees.delete(text);
  }

  // Reset position smoothly
  text.style.transition = 'transform 0.3s ease-out';
  text.style.transform = 'translateX(0)';
};

onMounted(fetchData);

// Cleanup timeouts on unmount to prevent memory leaks
onUnmounted(() => {
  // Clear search debounce timer
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
  // Clear marquee animation timeouts
  activeMarquees.forEach((timeouts) => {
    clearTimeout(timeouts.startTimeout);
    clearTimeout(timeouts.endTimeout);
    clearTimeout(timeouts.resetTimeout);
  });
  activeMarquees.clear();
});
</script>

<template>
  <div class="flex-1 overflow-auto bg-n-background">
    <KnowledgeBaseLayout
      :header-title="t('KNOWLEDGE_BASE.FAQ.HEADER_TITLE')"
      :button-label="t('KNOWLEDGE_BASE.FAQ.NEW_CATEGORY')"
      :show-button="!isLoading"
      @click="openNewCategory()"
      @close="showCategoryForm = false"
    >
      <!-- Category Form Dropdown (appears below New Category button) -->
      <template #action>
        <div
          v-if="showCategoryForm"
          class="w-[calc(100vw-2rem)] sm:w-96 max-w-96 z-50 absolute top-10 right-0 bg-n-alpha-3 backdrop-blur-[100px] p-4 sm:p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-4"
        >
          <div class="flex items-start justify-between">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ editingCategory ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EDIT') : t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NEW') }}
            </h3>
            <button class="text-n-slate-11 hover:text-n-slate-12" @click="showCategoryForm = false">
              <i class="i-lucide-x w-5 h-5" />
            </button>
          </div>
          <Input v-model="categoryForm.name" :label="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NAME')" :placeholder="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NAME_PLACEHOLDER')" />
          <Input v-model="categoryForm.description" :label="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DESCRIPTION')" :placeholder="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DESCRIPTION_PLACEHOLDER')" />
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1">{{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.PARENT') }}</label>
            <select v-model="categoryForm.parent_id" class="w-full h-10 px-3 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12">
              <option :value="null">{{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NO_PARENT') }}</option>
              <option v-for="cat in flatCategories.filter(c => c.level === 0 && c.id !== editingCategory?.id)" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
            </select>
          </div>
          <div class="flex gap-3">
            <Button variant="outline" :label="t('KNOWLEDGE_BASE.FAQ.CANCEL')" class="flex-1" @click="showCategoryForm = false" />
            <Button :label="t('KNOWLEDGE_BASE.FAQ.SAVE')" :is-loading="isSaving" :disabled="!categoryForm.name" class="flex-1" @click="saveCategory" />
          </div>
        </div>
      </template>

      <template #header-actions>
        <!-- New FAQ Button with Dropdown -->
        <div class="relative">
          <button
            class="h-8 px-3 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium flex items-center gap-2"
            @click="openNewFaq()"
          >
            <i class="i-lucide-plus w-4 h-4" />
            {{ t('KNOWLEDGE_BASE.FAQ.NEW_FAQ') }}
          </button>
          <!-- FAQ Form Dropdown -->
          <div
            v-if="showFaqForm"
            class="w-[calc(100vw-2rem)] sm:w-[28rem] max-w-[28rem] z-50 absolute top-10 right-0 bg-n-alpha-3 backdrop-blur-[100px] p-4 sm:p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-4"
          >
            <div class="flex items-start justify-between">
              <h3 class="text-base font-medium text-n-slate-12">
                {{ editingFaq ? t('KNOWLEDGE_BASE.FAQ.ITEMS.EDIT') : t('KNOWLEDGE_BASE.FAQ.ITEMS.NEW') }}
              </h3>
              <button class="text-n-slate-11 hover:text-n-slate-12" @click="showFaqForm = false">
                <i class="i-lucide-x w-5 h-5" />
              </button>
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1">
                {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.CATEGORY') }}
                <span class="text-n-ruby-11">*</span>
              </label>
              <select v-model="faqForm.faq_category_id" class="w-full h-10 px-3 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12" required>
                <option :value="null" disabled>{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.SELECT_CATEGORY') }}</option>
                <option v-for="cat in flatCategories" :key="cat.id" :value="cat.id">{{ cat.level > 0 ? '— ' : '' }}{{ cat.name }}</option>
              </select>
            </div>
            <div class="flex gap-2 border-b border-n-weak">
              <button :class="['px-4 py-2 text-sm font-medium border-b-2 -mb-px', activeLanguage === 'es' ? 'border-n-blue-9 text-n-blue-11' : 'border-transparent text-n-slate-11']" @click="activeLanguage = 'es'">Español</button>
              <button :class="['px-4 py-2 text-sm font-medium border-b-2 -mb-px', activeLanguage === 'en' ? 'border-n-blue-9 text-n-blue-11' : 'border-transparent text-n-slate-11']" @click="activeLanguage = 'en'">English</button>
            </div>
            <Input v-model="currentQuestion" :label="t('KNOWLEDGE_BASE.FAQ.ITEMS.QUESTION')" :placeholder="t('KNOWLEDGE_BASE.FAQ.ITEMS.QUESTION_PLACEHOLDER')" />
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1">{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.ANSWER') }}</label>
              <textarea v-model="currentAnswer" :placeholder="t('KNOWLEDGE_BASE.FAQ.ITEMS.ANSWER_PLACEHOLDER')" rows="12" class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 resize-y min-h-[200px]" />
            </div>
            <div class="flex gap-3">
              <Button variant="outline" :label="t('KNOWLEDGE_BASE.FAQ.CANCEL')" class="flex-1" @click="showFaqForm = false" />
              <Button :label="t('KNOWLEDGE_BASE.FAQ.SAVE')" :is-loading="isSaving" :disabled="!faqForm.faq_category_id || (!faqForm.translations.es?.question && !faqForm.translations.en?.question)" class="flex-1" @click="saveFaq" />
            </div>
          </div>
        </div>
      </template>

      <!-- Loading -->
      <div v-if="isLoading" class="flex items-center justify-center py-10">
        <Spinner />
      </div>

      <!-- Empty State -->
      <EmptyStateLayout
        v-else-if="isEmpty"
        :title="t('KNOWLEDGE_BASE.FAQ.EMPTY_STATE.TITLE')"
        :subtitle="t('KNOWLEDGE_BASE.FAQ.EMPTY_STATE.SUBTITLE')"
      >
        <template #empty-state-item>
          <div class="flex flex-col gap-4 p-px opacity-50 pointer-events-none">
            <div
              v-for="category in sampleCategories"
              :key="category.id"
              class="relative bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak overflow-hidden"
            >
              <!-- Category Header -->
              <div class="flex items-center justify-between p-4 border-b border-n-weak">
                <div class="flex items-center gap-3 flex-1 min-w-0">
                  <div class="p-1">
                    <i class="i-lucide-chevron-down w-4 h-4 text-n-slate-10" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="text-base font-medium text-n-slate-12 truncate">{{ category.name }}</div>
                    <div class="text-sm text-n-slate-10 truncate">{{ category.description }}</div>
                  </div>
                  <span class="text-xs text-n-slate-10 bg-n-alpha-2 px-2 py-1 rounded">
                    {{ category.faqs.length }} FAQs
                  </span>
                </div>
                <div class="flex items-center gap-2 ml-4">
                  <div class="p-2 text-n-slate-9 rounded-lg">
                    <i class="i-lucide-folder-plus w-4 h-4" />
                  </div>
                  <div class="p-2 text-n-slate-9 rounded-lg">
                    <i class="i-lucide-plus w-4 h-4" />
                  </div>
                  <div class="p-2 text-n-slate-9 rounded-lg">
                    <i class="i-lucide-pencil w-4 h-4" />
                  </div>
                </div>
              </div>
              <!-- FAQs -->
              <div class="bg-n-alpha-1 pl-10 py-2">
                <div
                  v-for="faq in category.faqs"
                  :key="faq.id"
                  class="flex items-center justify-between py-2 px-3"
                >
                  <div class="flex items-center gap-2 flex-1 min-w-0">
                    <i class="i-lucide-message-circle w-4 h-4 text-n-slate-10" />
                    <span class="text-sm text-n-slate-12 truncate">{{ faq.question }}</span>
                  </div>
                  <div class="flex items-center gap-1">
                    <div class="p-1.5 text-n-slate-9">
                      <i class="i-lucide-eye w-3.5 h-3.5" />
                    </div>
                    <div class="p-1.5 text-n-slate-9">
                      <i class="i-lucide-pencil w-3.5 h-3.5" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </EmptyStateLayout>

      <!-- Search Bar -->
      <div v-else class="space-y-4">
        <div class="flex items-center gap-2">
          <Input
            :model-value="searchQuery"
            type="search"
            :placeholder="t('KNOWLEDGE_BASE.FAQ.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
            @input="searchQuery = $event.target.value"
            @enter="handleSearchEnter"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
          <div v-if="!isSearching && meta.total_count !== undefined" class="text-sm text-n-slate-11 whitespace-nowrap">
            {{ meta.total_count }} {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.RESULTS') }}
          </div>
        </div>
        <!-- Language Filter -->
        <div class="flex items-center gap-2">
          <label class="text-xs text-n-slate-11 leading-7">{{ t('KNOWLEDGE_BASE.FAQ.FILTER_BY_LANGUAGE') }}:</label>
          <select
            v-model="displayLanguage"
            class="h-7 w-16 px-2 text-xs font-medium rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-3 transition-colors cursor-pointer"
          >
            <option value="es">ES</option>
            <option value="en">EN</option>
          </select>
        </div>

        <!-- Search Loading -->
        <div v-if="isSearching" class="flex items-center justify-center py-10">
          <Spinner />
        </div>

        <!-- No Search Results -->
        <div v-else-if="searchQuery && categories.length === 0" class="flex flex-col items-center justify-center py-16 text-center">
          <i class="i-lucide-search-x w-12 h-12 text-n-slate-9 mb-4" />
          <p class="text-n-slate-11 text-sm">
            {{ t('KNOWLEDGE_BASE.FAQ.NO_SEARCH_RESULTS') }}
          </p>
        </div>

        <!-- Categories List -->
        <div v-else class="flex flex-col gap-4">
          <template v-for="category in categories" :key="category.id">
          <CardLayout layout="col" class="!p-0">
            <!-- Category Header -->
            <div class="flex flex-col p-3 sm:p-4 border-b border-n-weak gap-2">
              <!-- Title row -->
              <div class="flex items-center gap-2 min-w-0">
                <button
                  class="p-1 hover:bg-n-alpha-2 rounded transition-colors flex-shrink-0"
                  :title="isExpanded(category.id) ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.COLLAPSE') : t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EXPAND')"
                  @click="toggleExpand(category.id)"
                >
                  <i :class="['w-4 h-4', isExpanded(category.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right']" />
                </button>
                <div class="flex-1 min-w-0">
                  <h3 class="text-sm sm:text-base font-medium text-n-slate-12 truncate">{{ category.name }}</h3>
                  <p v-if="category.description" class="text-xs sm:text-sm text-n-slate-10 truncate">{{ category.description }}</p>
                </div>
              </div>
              <!-- Actions row -->
              <div class="flex items-center justify-between gap-2 pl-7">
                <span class="text-xs text-n-slate-10 bg-n-alpha-2 px-2 py-1 rounded flex-shrink-0">
                  {{ getFaqsForCategory(category.id).length }} FAQs
                </span>
                <div class="flex items-center gap-1">
                  <Button variant="faded" size="xs" color="slate" icon="i-lucide-folder-plus" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ADD_SUBCATEGORY')" @click="openNewCategory(category.id)" />
                  <Button variant="faded" size="xs" color="slate" icon="i-lucide-plus" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ADD_FAQ')" @click="openNewFaq(category.id)" />
                  <Button variant="faded" size="xs" color="slate" icon="i-lucide-pencil" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EDIT_TOOLTIP')" @click="openEditCategory(category)" />
                  <Button variant="faded" size="xs" color="ruby" icon="i-lucide-trash" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_TOOLTIP')" @click="confirmDelete(category, 'category')" />
                </div>
              </div>
            </div>

            <!-- Expanded Content -->
            <div v-if="isExpanded(category.id)" class="bg-n-alpha-1">
              <!-- Subcategories -->
              <template v-for="sub in category.children" :key="sub.id">
                <div class="border-b border-n-weak last:border-b-0">
                  <div class="flex flex-col gap-1 p-2 sm:p-3 pl-4 sm:pl-10">
                    <!-- Subcategory title row -->
                    <div class="flex items-center gap-2 min-w-0">
                      <button class="p-1 hover:bg-n-alpha-2 rounded flex-shrink-0" :title="isExpanded(sub.id) ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.COLLAPSE') : t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EXPAND')" @click="toggleExpand(sub.id)">
                        <i :class="['w-4 h-4', isExpanded(sub.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right']" />
                      </button>
                      <span class="text-xs sm:text-sm font-medium text-n-slate-12 truncate flex-1">{{ sub.name }}</span>
                    </div>
                    <!-- Subcategory actions row -->
                    <div class="flex items-center justify-between gap-2 pl-7">
                      <span class="text-xs text-n-slate-10 bg-n-alpha-2 px-1.5 py-0.5 rounded flex-shrink-0">{{ getFaqsForCategory(sub.id).length }} FAQs</span>
                      <div class="flex items-center gap-1">
                        <Button variant="faded" size="xs" color="slate" icon="i-lucide-plus" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ADD_FAQ')" @click="openNewFaq(sub.id)" />
                        <Button variant="faded" size="xs" color="slate" icon="i-lucide-pencil" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EDIT_TOOLTIP')" @click="openEditCategory(sub)" />
                        <Button variant="faded" size="xs" color="ruby" icon="i-lucide-trash" :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_TOOLTIP')" @click="confirmDelete(sub, 'category')" />
                      </div>
                    </div>
                  </div>
                  <!-- Sub FAQs -->
                  <div v-if="isExpanded(sub.id)" class="pl-6 sm:pl-16 pb-2">
                    <div v-for="faq in getFaqsForCategory(sub.id)" :key="faq.id" class="py-1 px-1 sm:px-3">
                      <div class="flex items-center justify-between hover:bg-n-alpha-2 rounded py-1.5 px-1 sm:px-2">
                        <div class="flex items-center gap-1 sm:gap-2 flex-1 min-w-0 cursor-pointer" @click="toggleFaqExpand(faq.id)">
                          <button class="p-0.5 hover:bg-n-alpha-3 rounded flex-shrink-0">
                            <i :class="['w-3.5 h-3.5 text-n-slate-10', isFaqExpanded(faq.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right']" />
                          </button>
                          <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-1 sm:gap-2">
                              <span class="text-xs sm:text-sm text-n-slate-12 truncate">{{ getFaqQuestion(faq) }}</span>
                              <span v-if="!faq.is_visible" class="text-xs text-n-amber-11 bg-n-amber-3 px-1 sm:px-1.5 py-0.5 rounded flex-shrink-0">{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDDEN') }}</span>
                            </div>
                            <div v-if="!isFaqExpanded(faq.id) && getFaqAnswer(faq)" class="marquee-container mt-0.5 hidden sm:block" @mouseenter="startMarquee" @mouseleave="stopMarquee">
                              <span class="marquee-text text-xs text-n-slate-10">{{ getFaqAnswer(faq) }}</span>
                            </div>
                          </div>
                        </div>
                        <div class="flex items-center gap-0.5 sm:gap-1 flex-shrink-0">
                          <Button variant="faded" size="xs" class="hidden md:flex" color="slate" icon="i-lucide-chevron-up" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_UP')" :disabled="!canMoveUp(faq, sub.id)" @click.stop="moveFaq(faq, 'up')" />
                          <Button variant="faded" size="xs" class="hidden md:flex" color="slate" icon="i-lucide-chevron-down" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_DOWN')" :disabled="!canMoveDown(faq, sub.id)" @click.stop="moveFaq(faq, 'down')" />
                          <Button variant="faded" size="xs" class="hidden sm:flex" color="slate" :icon="faq.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'" :title="faq.is_visible ? t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDE_TOOLTIP') : t('KNOWLEDGE_BASE.FAQ.ITEMS.SHOW_TOOLTIP')" @click.stop="toggleFaqVisibility(faq)" />
                          <Button variant="faded" size="xs" color="slate" icon="i-lucide-pencil" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.EDIT_TOOLTIP')" @click.stop="openEditFaq(faq)" />
                          <Button variant="faded" size="xs" color="ruby" icon="i-lucide-trash" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE_TOOLTIP')" @click.stop="confirmDelete(faq, 'faq')" />
                        </div>
                      </div>
                      <!-- Expanded FAQ Content -->
                      <div v-if="isFaqExpanded(faq.id)" class="ml-4 sm:ml-8 mt-2 p-2 sm:p-3 bg-n-alpha-2 rounded-lg overflow-hidden">
                        <p class="text-xs sm:text-sm text-n-slate-11 whitespace-pre-wrap break-words overflow-hidden">{{ getFaqAnswer(faq) }}</p>
                      </div>
                    </div>
                    <div v-if="getFaqsForCategory(sub.id).length === 0" class="text-xs sm:text-sm text-n-slate-10 py-2 px-3">{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.EMPTY') }}</div>
                  </div>
                </div>
              </template>

              <!-- Category FAQs -->
              <div v-if="getFaqsForCategory(category.id).length > 0" class="pl-4 sm:pl-10 pb-2 pt-2">
                <div v-for="faq in getFaqsForCategory(category.id)" :key="faq.id" class="py-1 px-1 sm:px-3">
                  <div class="flex items-center justify-between hover:bg-n-alpha-2 rounded py-1.5 px-1 sm:px-2">
                    <div class="flex items-center gap-1 sm:gap-2 flex-1 min-w-0 cursor-pointer" @click="toggleFaqExpand(faq.id)">
                      <button class="p-0.5 hover:bg-n-alpha-3 rounded flex-shrink-0">
                        <i :class="['w-3.5 h-3.5 text-n-slate-10', isFaqExpanded(faq.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right']" />
                      </button>
                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-1 sm:gap-2">
                          <span class="text-xs sm:text-sm text-n-slate-12 truncate">{{ getFaqQuestion(faq) }}</span>
                          <span v-if="!faq.is_visible" class="text-xs text-n-amber-11 bg-n-amber-3 px-1 sm:px-1.5 py-0.5 rounded flex-shrink-0">{{ t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDDEN') }}</span>
                        </div>
                        <div v-if="!isFaqExpanded(faq.id) && getFaqAnswer(faq)" class="marquee-container mt-0.5 hidden sm:block" @mouseenter="startMarquee" @mouseleave="stopMarquee">
                          <span class="marquee-text text-xs text-n-slate-10">{{ getFaqAnswer(faq) }}</span>
                        </div>
                      </div>
                    </div>
                    <div class="flex items-center gap-0.5 sm:gap-1 flex-shrink-0">
                      <Button variant="faded" size="xs" class="hidden md:flex" color="slate" icon="i-lucide-chevron-up" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_UP')" :disabled="!canMoveUp(faq, category.id)" @click.stop="moveFaq(faq, 'up')" />
                      <Button variant="faded" size="xs" class="hidden md:flex" color="slate" icon="i-lucide-chevron-down" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.MOVE_DOWN')" :disabled="!canMoveDown(faq, category.id)" @click.stop="moveFaq(faq, 'down')" />
                      <Button variant="faded" size="xs" class="hidden sm:flex" color="slate" :icon="faq.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'" :title="faq.is_visible ? t('KNOWLEDGE_BASE.FAQ.ITEMS.HIDE_TOOLTIP') : t('KNOWLEDGE_BASE.FAQ.ITEMS.SHOW_TOOLTIP')" @click.stop="toggleFaqVisibility(faq)" />
                      <Button variant="faded" size="xs" color="slate" icon="i-lucide-pencil" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.EDIT_TOOLTIP')" @click.stop="openEditFaq(faq)" />
                      <Button variant="faded" size="xs" color="ruby" icon="i-lucide-trash" :title="t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE_TOOLTIP')" @click.stop="confirmDelete(faq, 'faq')" />
                    </div>
                  </div>
                  <!-- Expanded FAQ Content -->
                  <div v-if="isFaqExpanded(faq.id)" class="ml-4 sm:ml-8 mt-2 p-2 sm:p-3 bg-n-alpha-2 rounded-lg overflow-hidden">
                    <p class="text-xs sm:text-sm text-n-slate-11 whitespace-pre-wrap break-words overflow-hidden">{{ getFaqAnswer(faq) }}</p>
                  </div>
                </div>
              </div>

              <div v-if="getFaqsForCategory(category.id).length === 0 && (!category.children || category.children.length === 0)" class="text-xs sm:text-sm text-n-slate-10 py-4 px-4 sm:px-10">
                {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.EMPTY') }}
              </div>
            </div>
          </CardLayout>
          </template>
        </div>

        <!-- Pagination -->
        <div v-if="!searchQuery && meta && meta.total_pages > 1" class="flex flex-col sm:flex-row items-center justify-between gap-3 mt-6 px-4 py-3 bg-n-solid-1 rounded-lg">
          <div class="hidden sm:block text-sm text-n-slate-11">
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.SHOWING') }}
            <span class="font-medium text-n-slate-12">{{ (meta.current_page - 1) * 5 + 1 }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.TO') }}
            <span class="font-medium text-n-slate-12">{{ Math.min(meta.current_page * 5, meta.total_count) }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.OF') }}
            <span class="font-medium text-n-slate-12">{{ meta.total_count }}</span>
            {{ t('KNOWLEDGE_BASE.PRODUCT_CATALOG.PAGINATION.RESULTS') }}
          </div>
          <div class="sm:hidden text-xs text-n-slate-11">
            {{ meta.current_page }} / {{ meta.total_pages }}
          </div>

          <div class="flex items-center gap-1 sm:gap-2 flex-wrap justify-center">
            <button
              :disabled="meta.current_page === 1"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === 1
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(1)"
            >
              <i class="i-lucide-chevrons-left w-4 h-4" />
            </button>

            <button
              :disabled="meta.current_page === 1"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === 1
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.current_page - 1)"
            >
              <i class="i-lucide-chevron-left w-4 h-4" />
            </button>

            <div class="flex items-center gap-1">
              <template v-for="page in visiblePages" :key="page">
                <button
                  v-if="typeof page === 'number'"
                  :class="[
                    'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                    page === meta.current_page
                      ? 'bg-n-blue-9 text-white'
                      : 'text-n-slate-12 hover:bg-n-slate-3'
                  ]"
                  @click="handlePageChange(page)"
                >
                  {{ page }}
                </button>
                <span v-else class="px-2 text-n-slate-11">...</span>
              </template>
            </div>

            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === meta.total_pages
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.current_page + 1)"
            >
              <i class="i-lucide-chevron-right w-4 h-4" />
            </button>

            <button
              :disabled="meta.current_page === meta.total_pages"
              :class="[
                'px-3 py-1 rounded-md text-sm font-medium transition-colors',
                meta.current_page === meta.total_pages
                  ? 'text-n-slate-9 cursor-not-allowed'
                  : 'text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="handlePageChange(meta.total_pages)"
            >
              <i class="i-lucide-chevrons-right w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </KnowledgeBaseLayout>

    <!-- Delete Modal (stays as centered modal) -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="showDeleteModal = false">
      <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4">
        <div class="flex items-center gap-3 px-6 py-4 border-b border-n-weak">
          <div class="p-2 rounded-full bg-n-ruby-3">
            <i class="i-lucide-trash-2 w-5 h-5 text-n-ruby-11" />
          </div>
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ deleteType === 'category' ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE') : t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE') }}
          </h2>
        </div>
        <div class="px-6 py-4">
          <p class="text-sm text-n-slate-11 mb-3">
            {{ deleteType === 'category' ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_CONFIRM') : t('KNOWLEDGE_BASE.FAQ.ITEMS.DELETE_CONFIRM') }}
          </p>
          <div class="p-3 bg-n-alpha-2 rounded-lg">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ deleteType === 'category' ? itemToDelete?.name : (itemToDelete ? getFaqQuestion(itemToDelete) : '') }}
            </p>
          </div>
          <p v-if="deleteType === 'category'" class="mt-3 text-xs text-n-ruby-11">{{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE_WARNING') }}</p>
        </div>
        <div class="flex justify-end gap-2 px-6 py-4 border-t border-n-weak">
          <Button variant="faded" color="slate" :label="t('KNOWLEDGE_BASE.FAQ.CANCEL')" @click="showDeleteModal = false" />
          <Button color="ruby" :label="t('KNOWLEDGE_BASE.FAQ.DELETE')" :loading="isDeleting" @click="executeDelete" />
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.marquee-container {
  overflow: hidden;
  position: relative;
  width: 100%;
}

.marquee-text {
  display: inline-block;
  white-space: nowrap;
  transform: translateX(0);
  will-change: transform;
}
</style>
