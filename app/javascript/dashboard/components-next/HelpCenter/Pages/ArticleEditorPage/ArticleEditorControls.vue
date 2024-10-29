<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ArticleEditorProperties from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorProperties.vue';

const props = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['saveArticle', 'setAuthor', 'setCategory']);

const { t } = useI18n();

const openAgentsList = ref(false);
const openCategoryList = ref(false);
const openProperties = ref(false);
const selectedAuthorId = ref(null);
const selectedCategoryId = ref(null);

const agents = useMapGetter('agents/getAgents');
const categories = useMapGetter('categories/allCategories');
const currentUserId = useMapGetter('getCurrentUserID');

const isNewArticle = computed(() => !props.article?.id);

const currentUser = computed(() =>
  agents.value.find(agent => agent.id === currentUserId.value)
);

const author = computed(() => {
  if (isNewArticle.value) {
    return selectedAuthorId.value
      ? agents.value.find(agent => agent.id === selectedAuthorId.value)
      : currentUser.value;
  }
  return props.article?.author || currentUser.value;
});

const authorName = computed(
  () => author.value?.name || author.value?.available_name || '-'
);
const authorThumbnailSrc = computed(() => author.value?.thumbnail);

const agentList = computed(() => {
  return [...agents.value]
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(agent => ({
      label: agent.name,
      value: agent.id,
      thumbnail: { name: agent.name, src: agent.thumbnail },
      isSelected: agent.id === props.article?.author?.id,
      action: 'assignAuthor',
    }))
    .sort((a, b) => b.isSelected - a.isSelected);
});

const hasAgentList = computed(() => {
  return agents.value?.length > 0;
});

const selectedCategory = computed(() => {
  if (isNewArticle.value) {
    return selectedCategoryId.value
      ? categories.value.find(
          category => category.id === selectedCategoryId.value
        )
      : categories.value[0] || null;
  }
  return categories.value.find(
    category => category.id === props.article?.category?.id
  );
});

const categoryList = computed(() => {
  return categories.value
    .map(category => ({
      label: category.name,
      value: category.id,
      emoji: category.icon,
      isSelected: category.id === props.article?.category?.id,
      action: 'assignCategory',
    }))
    .sort((a, b) => b.isSelected - a.isSelected);
});

const hasCategoryMenuItems = computed(() => {
  return categoryList.value?.length > 0;
});

const handleArticleAction = ({ action, value }) => {
  const actions = {
    assignAuthor: () => {
      if (isNewArticle.value) {
        selectedAuthorId.value = value;
        emit('setAuthor', value);
      } else {
        emit('saveArticle', { author_id: value });
      }
      openAgentsList.value = false;
    },
    assignCategory: () => {
      if (isNewArticle.value) {
        selectedCategoryId.value = value;
        emit('setCategory', value);
      } else {
        emit('saveArticle', { category_id: value });
      }
      openCategoryList.value = false;
    },
  };

  actions[action]?.();
};

const updateMeta = meta => {
  emit('saveArticle', { meta });
};
</script>

<template>
  <div class="flex items-center gap-4">
    <div class="relative flex items-center gap-2">
      <OnClickOutside @trigger="openAgentsList = false">
        <Button
          :label="authorName"
          variant="ghost"
          class="!px-0 font-normal"
          text-variant="info"
          @click="openAgentsList = !openAgentsList"
        >
          <template #leftPrefix>
            <Thumbnail
              v-if="author"
              :author="author"
              :name="authorName"
              :size="20"
              :src="authorThumbnailSrc"
            />
          </template>
        </Button>
        <DropdownMenu
          v-if="openAgentsList && hasAgentList"
          :menu-items="agentList"
          class="z-[100] w-48 mt-2 overflow-y-auto ltr:left-0 rtl:right-0 top-full max-h-52"
          @action="handleArticleAction"
        />
      </OnClickOutside>
    </div>
    <div class="w-px h-3 bg-slate-50 dark:bg-slate-800" />
    <div class="relative">
      <OnClickOutside @trigger="openCategoryList = false">
        <Button
          :label="
            selectedCategory?.name ||
            t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.UNCATEGORIZED')
          "
          :emoji="selectedCategory?.icon || ''"
          :icon="!selectedCategory?.icon ? 'play-shape' : ''"
          variant="ghost"
          class="!px-2 font-normal"
          text-variant="info"
          @click="openCategoryList = !openCategoryList"
        />
        <DropdownMenu
          v-if="openCategoryList && hasCategoryMenuItems"
          :menu-items="categoryList"
          class="w-48 mt-2 z-[100] overflow-y-auto left-0 top-full max-h-52"
          @action="handleArticleAction"
        />
      </OnClickOutside>
    </div>

    <div class="w-px h-3 bg-slate-50 dark:bg-slate-800" />
    <div class="relative">
      <OnClickOutside @trigger="openProperties = false">
        <Button
          :label="
            t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.MORE_PROPERTIES')
          "
          icon="add"
          variant="ghost"
          :disabled="isNewArticle"
          text-variant="info"
          class="!px-2 font-normal"
          @click="openProperties = !openProperties"
        />
        <ArticleEditorProperties
          v-if="openProperties"
          :article="article"
          class="right-0 z-[100] mt-2 xl:left-0 top-full"
          @save-article="updateMeta"
          @close="openProperties = false"
        />
      </OnClickOutside>
    </div>
  </div>
</template>
