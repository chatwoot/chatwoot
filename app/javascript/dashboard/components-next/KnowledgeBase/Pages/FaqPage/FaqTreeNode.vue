<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  category: {
    type: Object,
    required: true,
  },
  selectedCategoryId: {
    type: [Number, String],
    default: null,
  },
  depth: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['select', 'add-subcategory', 'edit', 'delete']);

const { t } = useI18n();
const isExpanded = ref(true);
const showActions = ref(false);

const hasChildren = computed(() =>
  props.category.children && props.category.children.length > 0
);

const isSelected = computed(() =>
  props.selectedCategoryId === props.category.id
);

const canAddSubcategory = computed(() => props.depth < 1);

const paddingLeft = computed(() => `${props.depth * 16 + 12}px`);

const onToggle = (e) => {
  e.stopPropagation();
  isExpanded.value = !isExpanded.value;
};

const onSelect = () => {
  emit('select', props.category.id);
};

const onAddSubcategory = (e) => {
  e.stopPropagation();
  emit('add-subcategory', props.category.id);
};

const onEdit = (e) => {
  e.stopPropagation();
  emit('edit', props.category);
};

const onDelete = (e) => {
  e.stopPropagation();
  emit('delete', props.category);
};
</script>

<template>
  <div>
    <!-- Category Node -->
    <div
      class="group flex items-center gap-1 py-1.5 rounded-lg cursor-pointer transition-colors"
      :class="[
        isSelected
          ? 'bg-n-brand text-white'
          : 'hover:bg-n-alpha-2 text-n-slate-12'
      ]"
      :style="{ paddingLeft }"
      @click="onSelect"
      @mouseenter="showActions = true"
      @mouseleave="showActions = false"
    >
      <!-- Expand/Collapse Toggle -->
      <button
        v-if="hasChildren"
        class="p-0.5 rounded hover:bg-n-alpha-2"
        @click="onToggle"
      >
        <span
          class="size-4 transition-transform"
          :class="[
            isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'
          ]"
        />
      </button>
      <span v-else class="w-5" />

      <!-- Category Icon -->
      <span
        class="size-4"
        :class="[
          hasChildren ? 'i-lucide-folder' : 'i-lucide-folder-open'
        ]"
      />

      <!-- Category Name -->
      <span class="flex-1 text-sm truncate">
        {{ category.name }}
      </span>

      <!-- Item Count Badge -->
      <span
        v-if="category.faq_items_count > 0"
        class="text-xs px-1.5 py-0.5 rounded-full"
        :class="[
          isSelected ? 'bg-white/20' : 'bg-n-alpha-2'
        ]"
      >
        {{ category.faq_items_count }}
      </span>

      <!-- Actions -->
      <div
        v-if="showActions && !isSelected"
        class="flex items-center gap-0.5 pr-2"
      >
        <button
          v-if="canAddSubcategory"
          class="p-1 rounded hover:bg-n-alpha-3"
          :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.ADD_SUBCATEGORY')"
          @click="onAddSubcategory"
        >
          <span class="i-lucide-plus size-3" />
        </button>
        <button
          class="p-1 rounded hover:bg-n-alpha-3"
          :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EDIT')"
          @click="onEdit"
        >
          <span class="i-lucide-pencil size-3" />
        </button>
        <button
          class="p-1 rounded hover:bg-n-alpha-3 text-n-ruby-11"
          :title="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DELETE')"
          @click="onDelete"
        >
          <span class="i-lucide-trash-2 size-3" />
        </button>
      </div>
    </div>

    <!-- Children -->
    <div v-if="hasChildren && isExpanded">
      <FaqTreeNode
        v-for="child in category.children"
        :key="child.id"
        :category="child"
        :selected-category-id="selectedCategoryId"
        :depth="depth + 1"
        @select="emit('select', $event)"
        @add-subcategory="emit('add-subcategory', $event)"
        @edit="emit('edit', $event)"
        @delete="emit('delete', $event)"
      />
    </div>
  </div>
</template>
