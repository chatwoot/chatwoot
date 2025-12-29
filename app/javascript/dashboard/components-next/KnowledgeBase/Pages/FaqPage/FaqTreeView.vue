<script setup>
import { useI18n } from 'vue-i18n';
import FaqTreeNode from './FaqTreeNode.vue';

const props = defineProps({
  categories: {
    type: Array,
    default: () => [],
  },
  selectedCategoryId: {
    type: [Number, String],
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'add-category', 'edit-category', 'delete-category']);

const { t } = useI18n();

const onSelect = (categoryId) => {
  emit('select', categoryId);
};

const onAddCategory = (parentId) => {
  emit('add-category', parentId);
};

const onEditCategory = (category) => {
  emit('edit-category', category);
};

const onDeleteCategory = (category) => {
  emit('delete-category', category);
};

const onSelectAll = () => {
  emit('select', null);
};
</script>

<template>
  <div class="p-4">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.TITLE') }}
      </h3>
      <button
        class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-11"
        :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NEW')"
        @click="onAddCategory(null)"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="space-y-2">
      <div
        v-for="i in 3"
        :key="i"
        class="h-8 bg-n-alpha-2 rounded animate-pulse"
      />
    </div>

    <!-- Categories Tree -->
    <div v-else class="space-y-1">
      <!-- All Items Option -->
      <button
        class="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-left text-sm transition-colors"
        :class="[
          selectedCategoryId === null
            ? 'bg-n-brand text-white'
            : 'hover:bg-n-alpha-2 text-n-slate-12'
        ]"
        @click="onSelectAll"
      >
        <span class="i-lucide-list size-4" />
        <span>{{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ALL') }}</span>
      </button>

      <!-- Category Nodes -->
      <FaqTreeNode
        v-for="category in categories"
        :key="category.id"
        :category="category"
        :selected-category-id="selectedCategoryId"
        :depth="0"
        @select="onSelect"
        @add-subcategory="onAddCategory"
        @edit="onEditCategory"
        @delete="onDeleteCategory"
      />
    </div>

    <!-- Empty State -->
    <div
      v-if="!isLoading && categories.length === 0"
      class="text-center py-8 text-n-slate-10 text-sm"
    >
      {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EMPTY') }}
    </div>
  </div>
</template>
