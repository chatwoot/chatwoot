<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import InboxFaqCategoriesAPI from 'dashboard/api/inboxFaqCategories';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const props = defineProps({
  inboxId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const isLoading = ref(false);
const isSaving = ref(false);
const selectedCategoryIds = ref([]);
const expandedCategories = ref(new Set());

const categories = computed(() => store.getters['faqCategories/getTree']);
const isFetchingCategories = computed(
  () => store.getters['faqCategories/getUIFlags'].isFetching
);

const hasCategories = computed(
  () => categories.value && categories.value.length > 0
);

const fetchCategories = async () => {
  // Fetch all categories without pagination limit
  await store.dispatch('faqCategories/fetchTree', { per_page: 1000 });
};

const fetchSelectedCategories = async () => {
  try {
    isLoading.value = true;
    const response = await InboxFaqCategoriesAPI.getCategories(props.inboxId);
    selectedCategoryIds.value = (response.data.data || []).map(cat => cat.id);
  } catch (error) {
    useAlert(t('INBOX_MGMT.FAQ_CONFIGURATION.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const toggleCategory = categoryId => {
  const index = selectedCategoryIds.value.indexOf(categoryId);
  if (index > -1) {
    selectedCategoryIds.value.splice(index, 1);
  } else {
    selectedCategoryIds.value.push(categoryId);
  }
};

const toggleExpand = categoryId => {
  if (expandedCategories.value.has(categoryId)) {
    expandedCategories.value.delete(categoryId);
  } else {
    expandedCategories.value.add(categoryId);
  }
};

const isCategorySelected = categoryId => {
  return selectedCategoryIds.value.includes(categoryId);
};

const isExpanded = categoryId => {
  return expandedCategories.value.has(categoryId);
};

const saveSelection = async () => {
  try {
    isSaving.value = true;
    await InboxFaqCategoriesAPI.syncCategories(
      props.inboxId,
      selectedCategoryIds.value
    );
    // No alert here - parent component shows the success message
  } catch (error) {
    useAlert(t('INBOX_MGMT.FAQ_CONFIGURATION.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};

// Expand all categories on mount for better UX
const expandAll = () => {
  const collectIds = items => {
    items.forEach(item => {
      if (item.children && item.children.length > 0) {
        expandedCategories.value.add(item.id);
        collectIds(item.children);
      }
    });
  };
  collectIds(categories.value || []);
};

watch(categories, () => {
  if (categories.value && categories.value.length > 0) {
    expandAll();
  }
});

onMounted(async () => {
  await Promise.all([fetchCategories(), fetchSelectedCategories()]);
});

// Expose saveSelection for parent component to call
defineExpose({
  saveSelection,
  isSaving,
});
</script>

<template>
  <div class="faq-category-selector">
    <LoadingState v-if="isLoading || isFetchingCategories" />
    <template v-else>
      <div v-if="!hasCategories" class="text-sm text-n-slate-11 py-4">
        {{ t('INBOX_MGMT.FAQ_CONFIGURATION.NO_CATEGORIES') }}
      </div>
      <template v-else>
        <div class="category-tree max-h-64 overflow-y-auto border border-n-weak rounded-lg p-2 mb-4">
          <template v-for="category in categories" :key="category.id">
            <div class="category-item">
              <div class="flex items-center gap-2 py-1.5 px-2 hover:bg-n-alpha-2 rounded">
                <button
                  v-if="category.children && category.children.length > 0"
                  type="button"
                  class="p-0.5 hover:bg-n-alpha-3 rounded"
                  @click="toggleExpand(category.id)"
                >
                  <span
                    :class="[
                      'size-4 transition-transform',
                      isExpanded(category.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'
                    ]"
                  />
                </button>
                <span v-else class="w-5" />
                <label class="flex items-center gap-2 cursor-pointer flex-1">
                  <input
                    type="checkbox"
                    :checked="isCategorySelected(category.id)"
                    class="form-checkbox rounded text-woot-500"
                    @change="toggleCategory(category.id)"
                  />
                  <span class="text-sm text-n-slate-12">{{ category.name }}</span>
                </label>
              </div>
              <div
                v-if="category.children && category.children.length > 0 && isExpanded(category.id)"
                class="ml-6"
              >
                <div
                  v-for="child in category.children"
                  :key="child.id"
                  class="flex items-center gap-2 py-1.5 px-2 hover:bg-n-alpha-2 rounded"
                >
                  <span class="w-5" />
                  <label class="flex items-center gap-2 cursor-pointer flex-1">
                    <input
                      type="checkbox"
                      :checked="isCategorySelected(child.id)"
                      class="form-checkbox rounded text-woot-500"
                      @change="toggleCategory(child.id)"
                    />
                    <span class="text-sm text-n-slate-11">{{ child.name }}</span>
                  </label>
                </div>
              </div>
            </div>
          </template>
        </div>
        <div class="text-xs text-n-slate-10">
          {{ t('INBOX_MGMT.FAQ_CONFIGURATION.SELECTED_COUNT', { count: selectedCategoryIds.length }) }}
        </div>
      </template>
    </template>
  </div>
</template>
