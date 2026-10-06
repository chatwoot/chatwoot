<script setup>
import { computed, reactive, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import ArticleSlugField from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleSlugField.vue';

const props = defineProps({
  article: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits([
  'saveArticle',
  'saveSlug',
  'previewArticle',
  'close',
]);

const saveArticle = debounce(value => emit('saveArticle', value), 400, false);

const { t } = useI18n();
const route = useRoute();
const portalBySlug = useMapGetter('portals/portalBySlug');

// The portal setting overrides the article's own, so the switch is locked off while it is hidden.
const isPortalHiddenFromSearch = computed(
  () =>
    portalBySlug.value(route.params.portalSlug)?.config
      ?.disable_search_indexing || false
);

const state = reactive({
  title: '',
  description: '',
  tags: [],
  noindex: false,
});

const updateState = () => {
  state.title = props.article.meta?.title || '';
  state.description = props.article.meta?.description || '';
  state.tags = props.article.meta?.tags || [];
  state.noindex = props.article.meta?.noindex || false;
};

watch(
  state,
  newState => {
    saveArticle({
      title: newState.title,
      description: newState.description,
      tags: newState.tags,
      noindex: newState.noindex,
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
        <div class="flex flex-col gap-1 py-2">
          <div class="flex items-center justify-between w-full gap-3">
            <label class="text-sm font-medium text-n-slate-12">
              {{
                t(
                  'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SEARCH_ENGINE_VISIBILITY'
                )
              }}
            </label>
            <Switch
              :model-value="!isPortalHiddenFromSearch && !state.noindex"
              :disabled="isPortalHiddenFromSearch"
              @change="state.noindex = !state.noindex"
            />
          </div>
          <span v-if="isPortalHiddenFromSearch" class="text-sm text-n-slate-11">
            {{
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SEARCH_ENGINE_VISIBILITY_PORTAL_OVERRIDE'
              )
            }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
