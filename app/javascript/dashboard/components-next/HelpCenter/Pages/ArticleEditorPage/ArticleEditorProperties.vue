<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useDebounceFn } from '@vueuse/core';
import { debounce } from '@chatwoot/utils';
import camelcaseKeys from 'camelcase-keys';

import articlesAPI from 'dashboard/api/helpCenter/articles';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ArticleSlugField from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleSlugField.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  article: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits([
  'saveArticle',
  'saveSlug',
  'saveAssociation',
  'previewArticle',
  'close',
]);

const saveArticle = debounce(value => emit('saveArticle', value), 400, false);

const { t } = useI18n();
const route = useRoute();

const articleOptions = ref([]);
const associationSelectionKey = ref(0);
let articleSearchId = 0;

const articleLabel = article => {
  const locale = article.locale ? ` (${article.locale})` : '';
  return `${article.title}${locale}`;
};

const rootArticleId = computed(() => props.article.associatedArticleId || '');
const rootArticleTitle = computed(() =>
  props.article.rootArticle ? articleLabel(props.article.rootArticle) : ''
);

const selectableArticleOptions = computed(() => {
  const options = [...articleOptions.value];
  const rootArticle = props.article.rootArticle;

  if (rootArticle && !options.some(option => option.value === rootArticle.id)) {
    options.unshift({
      label: articleLabel(rootArticle),
      value: rootArticle.id,
    });
  }

  return options;
});

const fetchArticles = async query => {
  articleSearchId += 1;
  const searchId = articleSearchId;

  try {
    const {
      data: { payload },
    } = await articlesAPI.searchArticles({
      portalSlug: route.params.portalSlug,
      query,
    });

    const options = camelcaseKeys(payload || [])
      .filter(article => article.id !== props.article.id)
      .map(article => ({
        label: articleLabel(article),
        value: article.id,
      }));

    if (searchId === articleSearchId) {
      articleOptions.value = options;
    }
  } catch {
    if (searchId === articleSearchId) {
      articleOptions.value = [];
    }
  }
};

const handleArticleSearch = useDebounceFn(query => {
  fetchArticles(query?.trim() || '');
}, 300);

const handleAssociationChange = articleId => {
  emit('saveAssociation', articleId ? Number(articleId) : null);
  associationSelectionKey.value += 1;
};

const state = reactive({
  title: '',
  description: '',
  tags: [],
});

const updateState = () => {
  state.title = props.article.meta?.title || '';
  state.description = props.article.meta?.description || '';
  state.tags = props.article.meta?.tags || [];
};

watch(
  state,
  newState => {
    saveArticle({
      title: newState.title,
      description: newState.description,
      tags: newState.tags,
    });
  },
  { deep: true }
);

onMounted(() => {
  updateState();
});
</script>

<template>
  <div
    class="flex flex-col absolute w-[25rem] bg-n-alpha-3 outline outline-1 outline-n-container backdrop-blur-[100px] shadow-lg gap-6 rounded-xl p-6"
  >
    <div class="flex items-center justify-between">
      <h3>
        {{
          t(
            'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ARTICLE_PROPERTIES'
          )
        }}
      </h3>
      <Button
        icon="i-lucide-x"
        size="sm"
        variant="ghost"
        color="slate"
        class="hover:text-n-slate-11"
        @click="emit('close')"
      />
    </div>
    <div class="flex flex-col gap-2">
      <div>
        <ArticleSlugField
          :article="article"
          @save-slug="slug => emit('saveSlug', slug)"
          @preview-article="emit('previewArticle')"
        />
        <div class="flex justify-between w-full gap-4 py-2">
          <label
            class="text-sm font-medium whitespace-nowrap min-w-[7.5rem] text-n-slate-12"
          >
            {{
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ORIGINAL_ARTICLE'
              )
            }}
          </label>
          <ComboBox
            :key="associationSelectionKey"
            :model-value="rootArticleId"
            :options="selectableArticleOptions"
            :display-label="rootArticleTitle"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ORIGINAL_ARTICLE_PLACEHOLDER'
              )
            "
            :search-placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ORIGINAL_ARTICLE_SEARCH'
              )
            "
            :empty-state="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ORIGINAL_ARTICLE_EMPTY'
              )
            "
            use-api-results
            class="w-[14rem] [&>div>div_ul]:max-h-56"
            @open="fetchArticles('')"
            @search="handleArticleSearch"
            @update:model-value="handleAssociationChange"
          />
        </div>
        <div class="flex justify-between w-full gap-4 py-2">
          <label
            class="text-sm font-medium whitespace-nowrap min-w-[6.25rem] text-n-slate-12"
          >
            {{
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION'
              )
            }}
          </label>
          <TextArea
            v-model="state.description"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION_PLACEHOLDER'
              )
            "
            class="w-[13.75rem]"
            custom-text-area-wrapper-class="!p-0 !border-0 !rounded-none !bg-transparent transition-none"
            custom-text-area-class="max-h-[9.375rem]"
            auto-height
            min-height="3rem"
          />
        </div>
        <div class="flex justify-between w-full gap-2 py-2">
          <InlineInput
            v-model="state.title"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE_PLACEHOLDER'
              )
            "
            :label="
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE')
            "
            custom-label-class="min-w-[7.5rem]"
          />
        </div>
        <div class="flex justify-between w-full gap-3 py-2">
          <label
            class="text-sm font-medium whitespace-nowrap min-w-[7.5rem] text-n-slate-12"
          >
            {{
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS')
            }}
          </label>
          <TagInput
            v-model="state.tags"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS_PLACEHOLDER'
              )
            "
            class="w-[14rem]"
          />
        </div>
      </div>
    </div>
  </div>
</template>
