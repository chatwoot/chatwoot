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
    return `${props.category.icon} ${props.category.name}`;
  }
  return t(
    'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.CATEGORY.UNCATEGORISED'
  );
});

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
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <span
        class="text-base cursor-pointer hover:underline underline-offset-2 hover:text-n-blue-text text-n-slate-12 line-clamp-1"
        @click="handleClick(id)"
      >
        {{ title }}
      </span>
      <div class="flex items-center gap-2">
        <span
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
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
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="articleMenuItems"
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:left-0 xl:rtl:right-0 top-full"
            @action="handleArticleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-1">
          <Avatar
            :name="authorName"
            :src="authorThumbnailSrc"
            :size="16"
            rounded-full
          />
          <span class="text-sm truncate text-n-slate-11">
            {{ authorName || '-' }}
          </span>
        </div>
        <span class="block text-sm whitespace-nowrap text-n-slate-11">
          {{ categoryName }}
        </span>
        <div
          class="inline-flex items-center gap-1 text-n-slate-11 whitespace-nowrap"
        >
          <Icon icon="i-lucide-eye" class="size-4" />
          <span class="text-sm">
            {{
              t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.VIEWS', {
                count: views,
              })
            }}
          </span>
        </div>
      </div>
      <span class="text-sm text-n-slate-11 line-clamp-1">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
