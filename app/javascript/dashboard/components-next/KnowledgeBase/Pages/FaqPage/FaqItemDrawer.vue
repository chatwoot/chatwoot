<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const props = defineProps({
  item: {
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

const LANGUAGES = [
  { code: 'es', name: 'Español' },
  { code: 'en', name: 'English' },
];

const categoryId = ref(null);
const activeLanguage = ref('es');
const translations = ref({});

const isEditing = computed(() => props.item?.id);
const title = computed(() =>
  isEditing.value
    ? t('KNOWLEDGE_BASE.FAQ.ITEMS.EDIT')
    : t('KNOWLEDGE_BASE.FAQ.ITEMS.NEW')
);

const flatCategories = computed(() => {
  const result = [];
  const flatten = (cats, depth = 0) => {
    cats.forEach(cat => {
      result.push({ ...cat, depth });
      if (cat.children) {
        flatten(cat.children, depth + 1);
      }
    });
  };
  flatten(props.categories);
  return result;
});

const currentTranslation = computed(() =>
  translations.value[activeLanguage.value] || { question: '', answer: '' }
);

const isValid = computed(() => {
  // At least one language must have both question and answer
  return Object.values(translations.value).some(
    t => t.question?.trim() && t.answer?.trim()
  );
});

const hasTranslation = (langCode) => {
  const t = translations.value[langCode];
  return t && t.question?.trim() && t.answer?.trim();
};

const updateQuestion = (value) => {
  if (!translations.value[activeLanguage.value]) {
    translations.value[activeLanguage.value] = { question: '', answer: '' };
  }
  translations.value[activeLanguage.value].question = value;
};

const updateAnswer = (value) => {
  if (!translations.value[activeLanguage.value]) {
    translations.value[activeLanguage.value] = { question: '', answer: '' };
  }
  translations.value[activeLanguage.value].answer = value;
};

const onClose = () => {
  emit('close');
};

const onSave = () => {
  if (!isValid.value) return;

  // Clean empty translations
  const cleanTranslations = {};
  Object.entries(translations.value).forEach(([lang, t]) => {
    if (t.question?.trim() && t.answer?.trim()) {
      cleanTranslations[lang] = {
        question: t.question.trim(),
        answer: t.answer.trim(),
      };
    }
  });

  emit('save', {
    faq_category_id: categoryId.value,
    translations: cleanTranslations,
  });
};

onMounted(() => {
  if (props.item) {
    categoryId.value = props.item.faq_category_id || null;
    translations.value = JSON.parse(JSON.stringify(props.item.translations || {}));
  }

  // Initialize empty translations for both languages if needed
  LANGUAGES.forEach(lang => {
    if (!translations.value[lang.code]) {
      translations.value[lang.code] = { question: '', answer: '' };
    }
  });
});
</script>

<template>
  <div class="fixed inset-0 z-50 flex">
    <!-- Backdrop -->
    <div
      class="absolute inset-0 bg-black/50"
      @click="onClose"
    />

    <!-- Drawer -->
    <div class="relative ml-auto w-full max-w-2xl bg-n-solid-1 shadow-xl flex flex-col h-full">
      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak shrink-0">
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
      <div class="flex-1 overflow-y-auto px-6 py-4 space-y-6">
        <!-- Category -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.CATEGORY') }}
          </label>
          <select
            v-model="categoryId"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option :value="null">
              {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.NO_CATEGORY') }}
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

        <!-- Language Tabs -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-2">
            {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.TRANSLATIONS') }}
          </label>
          <div class="flex gap-1 border-b border-n-weak">
            <button
              v-for="lang in LANGUAGES"
              :key="lang.code"
              class="relative px-4 py-2 text-sm font-medium transition-colors"
              :class="[
                activeLanguage === lang.code
                  ? 'text-n-brand'
                  : 'text-n-slate-11 hover:text-n-slate-12'
              ]"
              @click="activeLanguage = lang.code"
            >
              <span class="flex items-center gap-2">
                {{ lang.name }}
                <span
                  v-if="hasTranslation(lang.code)"
                  class="size-2 rounded-full bg-n-jade-9"
                />
              </span>
              <span
                v-if="activeLanguage === lang.code"
                class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand"
              />
            </button>
          </div>
        </div>

        <!-- Question -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.QUESTION') }} *
          </label>
          <input
            :value="currentTranslation.question"
            type="text"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="t('KNOWLEDGE_BASE.FAQ.ITEMS.QUESTION_PLACEHOLDER')"
            @input="updateQuestion($event.target.value)"
          />
        </div>

        <!-- Answer (Rich Text) -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.ANSWER') }} *
          </label>
          <div class="border border-n-weak rounded-lg overflow-hidden">
            <WootMessageEditor
              :value="currentTranslation.answer"
              :placeholder="t('KNOWLEDGE_BASE.FAQ.ITEMS.ANSWER_PLACEHOLDER')"
              :enable-suggestions="false"
              class="min-h-[200px]"
              @input="updateAnswer"
            />
          </div>
          <p class="mt-1 text-xs text-n-slate-10">
            {{ t('KNOWLEDGE_BASE.FAQ.ITEMS.ANSWER_HELP') }}
          </p>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end gap-2 px-6 py-4 border-t border-n-weak shrink-0">
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
