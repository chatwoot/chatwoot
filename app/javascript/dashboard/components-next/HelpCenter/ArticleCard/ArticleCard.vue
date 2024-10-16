<script setup>
import { computed, ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  ARTICLE_MENU_ITEMS,
  ARTICLE_MENU_OPTIONS,
  ARTICLE_STATUSES,
} from 'dashboard/helper/portalHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  author: {
    type: Object,
    required: true,
  },
  category: {
    type: Object,
    required: true,
  },
  views: {
    type: Number,
    required: true,
  },
  updatedAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['openArticle', 'articleAction']);

const { t } = useI18n();

const isOpen = ref(false);

const articleMenuItems = computed(() => {
  const commonItems = Object.entries(ARTICLE_MENU_ITEMS).reduce(
    (acc, [key, item]) => {
      acc[key] = { ...item, label: t(item.label) };
      return acc;
    },
    {}
  );

  const statusItems = (
    ARTICLE_MENU_OPTIONS[props.status] ||
    ARTICLE_MENU_OPTIONS[ARTICLE_STATUSES.PUBLISHED]
  ).map(key => commonItems[key]);

  return [...statusItems, commonItems.delete];
});

const statusTextColor = computed(() => {
  switch (props.status) {
    case 'archived':
      return '!text-slate-600 dark:!text-slate-200';
    case 'draft':
      return '!text-amber-700 dark:!text-amber-400';
    default:
      return '!text-teal-700 dark:!text-teal-400';
  }
});

const statusText = computed(() => {
  switch (props.status) {
    case 'archived':
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.ARCHIVED');
    case 'draft':
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.DRAFT');
    default:
      return t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.STATUS.PUBLISHED');
  }
});

const categoryName = computed(() => {
  if (props.category?.slug) {
    return `${props.category.icon} ${props.category.name}`;
  }
  return t(
    'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.CATEGORY.UNCATEGORISED'
  );
});

const authorName = computed(() => {
  return props.author?.name || props.author?.availableName || '-';
});

const authorThumbnailSrc = computed(() => {
  return props.author?.thumbnail;
});

const lastUpdatedAt = computed(() => {
  return dynamicTime(props.updatedAt);
});

const handleArticleAction = ({ action, value }) => {
  isOpen.value = false;
  emit('articleAction', { action, value, id: props.id });
};

const handleClick = id => {
  emit('openArticle', id);
};
</script>

<template>
  <CardLayout @click="handleClick(id)">
    <template #header>
      <div class="flex justify-between gap-1">
        <span
          class="text-base group-hover/cardLayout:underline text-slate-900 dark:text-slate-50 line-clamp-1"
        >
          {{ title }}
        </span>
        <div class="relative group" @click.stop>
          <Button
            variant="ghost"
            size="sm"
            class="text-xs bg-slate-50 !font-normal group-hover:bg-slate-100/50 dark:group-hover:bg-slate-700/50 !h-6 dark:bg-slate-800 rounded-md border-0 !px-2 !py-0.5"
            :label="statusText"
            :class="statusTextColor"
            @click="isOpen = !isOpen"
          />
          <OnClickOutside @trigger="isOpen = false">
            <DropdownMenu
              v-if="isOpen"
              :menu-items="articleMenuItems"
              class="right-0 mt-2 xl:left-0 top-full"
              @action="handleArticleAction($event)"
            />
          </OnClickOutside>
        </div>
      </div>
    </template>
    <template #footer>
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1">
            <Thumbnail
              v-if="author"
              :author="author"
              :name="authorName"
              :src="authorThumbnailSrc"
            />
            <span class="text-sm text-slate-500 dark:text-slate-400">
              {{ authorName }}
            </span>
          </div>
          <span
            class="block text-sm whitespace-nowrap text-slate-500 dark:text-slate-400"
          >
            {{ categoryName }}
          </span>
          <div
            class="inline-flex items-center gap-1 text-slate-500 dark:text-slate-400 whitespace-nowrap"
          >
            <FluentIcon icon="eye-show" size="18" />
            <span class="text-sm">
              {{
                t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.VIEWS', {
                  count: views,
                })
              }}
            </span>
          </div>
        </div>
        <span class="text-sm text-slate-600 dark:text-slate-400 line-clamp-1">
          {{ lastUpdatedAt }}
        </span>
      </div>
    </template>
  </CardLayout>
</template>
