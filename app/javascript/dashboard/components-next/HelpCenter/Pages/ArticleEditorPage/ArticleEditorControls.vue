<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { OnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
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
const route = useRoute();

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

const categorySlugFromRoute = computed(() => route.params.categorySlug);

const author = computed(() => {
  if (isNewArticle.value) {
    return selectedAuthorId.value
      ? agents.value.find(agent => agent.id === selectedAuthorId.value)
      : currentUser.value;
  }
  return props.article?.author || null;
});

const authorName = computed(
  () => author.value?.name || author.value?.available_name || ''
);
const authorThumbnailSrc = computed(() => author.value?.thumbnail);

const agentList = computed(() => {
  return (
    agents.value
      ?.map(({ name, id, thumbnail }) => ({
        label: name,
        value: id,
        thumbnail: { name, src: thumbnail },
        isSelected: props.article?.author?.id
          ? id === props.article.author.id
          : id === (selectedAuthorId.value || currentUserId.value),
        action: 'assignAuthor',
      }))
      // Sort the list by isSelected first, then by name(label)
      .toSorted((a, b) => {
        if (a.isSelected !== b.isSelected) {
          return Number(b.isSelected) - Number(a.isSelected);
        }
        return a.label.localeCompare(b.label);
      }) ?? []
  );
});

const hasAgentList = computed(() => {
  return agents.value?.length > 1;
});

const findCategoryFromSlug = slug => {
  return categories.value?.find(category => category.slug === slug);
};

const assignCategoryFromSlug = slug => {
  const categoryFromSlug = findCategoryFromSlug(slug);
  if (categoryFromSlug) {
    selectedCategoryId.value = categoryFromSlug.id;
    return categoryFromSlug;
  }
  return null;
};

const selectedCategory = computed(() => {
  if (isNewArticle.value) {
    if (categorySlugFromRoute.value) {
      const categoryFromSlug = assignCategoryFromSlug(
        categorySlugFromRoute.value
      );
      if (categoryFromSlug) return categoryFromSlug;
    }
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
  return (
    categories.value
      .map(({ name, id, icon }) => ({
        label: name,
        value: id,
        emoji: icon,
        isSelected: isNewArticle.value
          ? id === (selectedCategoryId.value || selectedCategory.value?.id)
          : id === props.article?.category?.id,
        action: 'assignCategory',
      }))
      // Sort categories by isSelected
      .toSorted((a, b) => Number(b.isSelected) - Number(a.isSelected))
  );
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

onMounted(() => {
  if (categorySlugFromRoute.value && isNewArticle.value) {
    // Assign category from slug if there is one
    const categoryFromSlug = findCategoryFromSlug(categorySlugFromRoute.value);
    if (categoryFromSlug) {
      handleArticleAction({
        action: 'assignCategory',
        value: categoryFromSlug?.id,
      });
    }
  }
});
</script>

<template>
  <div class="flex items-center gap-4">
    <div class="relative flex items-center gap-2">
      <OnClickOutside @trigger="openAgentsList = false">
        <Button
          variant="ghost"
          class="!px-0 font-normal hover:!bg-transparent"
          text-variant="info"
          @click="openAgentsList = !openAgentsList"
        >
          <Avatar
            :name="authorName"
            :src="authorThumbnailSrc"
            :size="20"
            rounded-full
          />
          <span class="text-sm text-n-slate-12 hover:text-n-slate-11">
            {{ authorName || '-' }}
          </span>
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
          :icon="!selectedCategory?.icon ? 'i-lucide-shapes' : ''"
          variant="ghost"
          class="!px-2 font-normal hover:!bg-transparent"
          @click="openCategoryList = !openCategoryList"
        >
          <span
            v-if="selectedCategory"
            class="text-sm text-n-slate-12 hover:text-n-slate-11"
          >
            {{
              `${selectedCategory.icon || ''} ${selectedCategory.name || t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.UNCATEGORIZED')}`
            }}
          </span>
        </Button>
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
          icon="i-lucide-plus"
          variant="ghost"
          :disabled="isNewArticle"
          class="!px-2 font-normal hover:!bg-transparent hover:!text-n-slate-11"
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
