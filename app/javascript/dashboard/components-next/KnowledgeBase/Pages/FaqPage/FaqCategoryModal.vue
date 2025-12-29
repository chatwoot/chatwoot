<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  category: {
    type: Object,
    default: null,
  },
  categories: {
    type: Array,
    default: () => [],
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'save']);

const { t } = useI18n();

const name = ref('');
const description = ref('');
const parentId = ref(null);

const isEditing = computed(() => props.category?.id);
const title = computed(() =>
  isEditing.value
    ? t('KNOWLEDGE_BASE.FAQ.CATEGORIES.EDIT')
    : t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NEW')
);

const flatCategories = computed(() => {
  const result = [];
  const flatten = (cats, depth = 0) => {
    cats.forEach(cat => {
      // Don't show current category or its children as parent options
      if (isEditing.value && cat.id === props.category.id) return;
      result.push({ ...cat, depth });
      if (cat.children && depth < 1) {
        flatten(cat.children, depth + 1);
      }
    });
  };
  flatten(props.categories);
  return result;
});

const isValid = computed(() => name.value.trim().length > 0);

const onClose = () => {
  emit('close');
};

const onSave = () => {
  if (!isValid.value) return;

  emit('save', {
    name: name.value.trim(),
    description: description.value.trim(),
    parent_id: parentId.value,
  });
};

onMounted(() => {
  if (props.category) {
    name.value = props.category.name || '';
    description.value = props.category.description || '';
    parentId.value = props.category.parent_id || null;
  }
});
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    @click.self="onClose"
  >
    <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4">
      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ title }}
        </h2>
        <button
          class="p-1 rounded-lg hover:bg-n-alpha-2 text-n-slate-11"
          @click="onClose"
        >
          <span class="i-lucide-x size-5" />
        </button>
      </div>

      <!-- Body -->
      <div class="px-6 py-4 space-y-4">
        <!-- Name -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NAME') }} *
          </label>
          <input
            v-model="name"
            type="text"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NAME_PLACEHOLDER')"
          />
        </div>

        <!-- Description -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DESCRIPTION') }}
          </label>
          <textarea
            v-model="description"
            rows="3"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
            :placeholder="t('KNOWLEDGE_BASE.FAQ.CATEGORIES.DESCRIPTION_PLACEHOLDER')"
          />
        </div>

        <!-- Parent Category -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.PARENT') }}
          </label>
          <select
            v-model="parentId"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option :value="null">
              {{ t('KNOWLEDGE_BASE.FAQ.CATEGORIES.NO_PARENT') }}
            </option>
            <option
              v-for="cat in flatCategories"
              :key="cat.id"
              :value="cat.id"
            >
              {{ '—'.repeat(cat.depth) }} {{ cat.name }}
            </option>
          </select>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-n-weak">
        <woot-button
          color-scheme="secondary"
          size="small"
          @click="onClose"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.CANCEL') }}
        </woot-button>
        <woot-button
          color-scheme="primary"
          size="small"
          :disabled="!isValid || isSaving"
          :loading="isSaving"
          @click="onSave"
        >
          {{ t('KNOWLEDGE_BASE.FAQ.SAVE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
