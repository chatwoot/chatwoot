<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  ARTICLE_MENU_ITEMS,
  ARTICLE_MENU_OPTIONS,
  ARTICLE_STATUSES,
} from 'dashboard/helper/portalHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

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
    default: null,
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

const [showActionsDropdown, toggleDropdown] = useToggle();

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
      return 'text-n-slate-12';
    case 'draft':
      return 'text-n-amber-11';
    default:
      return 'text-n-teal-11';
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
    return props.category.name;
  }
  return t(
    'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.CATEGORY.UNCATEGORISED'
  );
});

const categoryIcon = computed(() => props.category?.icon || '');

const authorName = computed(() => {
  return props.author?.name || props.author?.availableName || '';
});

const authorThumbnailSrc = computed(() => {
  return props.author?.thumbnail;
});

const lastUpdatedAt = computed(() => {
  return dynamicTime(props.updatedAt);
});

const handleArticleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('articleAction', { action, value, id: props.id });
};

const handleClick = id => {
  emit('openArticle', id);
};
</script>

<template>
  <CardLayout class="[&>div]:!pt-3 group/articleCard hover:bg-n-alpha-1">
    <div class="flex justify-between w-full gap-1">
      <span
        class="text-sm cursor-pointer py-1.5 font-medium underline-offset-2 group-hover/articleCard:text-n-blue-11 text-n-slate-12 line-clamp-1"
        @click="handleClick(id)"
      >
        {{ title }}
      </span>
      <div class="flex items-center gap-2">
        <span
          class="text-xs font-440 outline outline-1 outline-n-container inline-flex items-center px-2 h-6 rounded-md bg-n-button-color"
          :class="statusTextColor"
        >
          {{ statusText }}
        </span>
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            slate
            :variant="!showActionsDropdown ? 'ghost' : 'faded'"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="articleMenuItems"
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleArticleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4 min-w-0">
      <div class="flex items-center gap-3 min-w-0 overflow-hidden">
        <div class="flex items-center gap-1.5 min-w-0 shrink">
          <Avatar
            :name="authorName"
            :src="authorThumbnailSrc"
            :size="16"
            rounded-full
            class="shrink-0"
          />
          <span class="text-sm font-420 truncate text-n-slate-11">
            {{ authorName || '-' }}
          </span>
        </div>
        <div class="w-px h-3 bg-n-weak rounded-lg shrink-0" />
        <div
          v-if="category"
          class="flex items-center gap-1.5 text-n-slate-11 min-w-0 shrink"
        >
          <span v-if="categoryIcon" class="text-sm shrink-0">
            {{ categoryIcon }}
          </span>
          <Icon v-else icon="i-lucide-shapes" class="size-4 shrink-0" />
          <span class="text-sm font-420 truncate">
            {{ categoryName }}
          </span>
        </div>
        <div v-if="category" class="w-px h-3 bg-n-weak rounded-lg shrink-0" />
        <div class="flex items-center gap-1.5 text-n-slate-11 shrink-0">
          <Icon icon="i-lucide-trending-up" class="size-4" />
          <span class="text-sm font-420 whitespace-nowrap">
            {{
              t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.VIEWS', {
                count: views,
              })
            }}
          </span>
        </div>
      </div>
      <span class="text-sm text-n-slate-11 truncate">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
