<script setup>
import { computed, useTemplateRef } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  ARTICLE_MENU_ITEMS,
  ARTICLE_MENU_OPTIONS,
  ARTICLE_STATUSES,
  getArticleStatus,
} from 'dashboard/helper/portalHelper';
import ArticlePendingChangesPopover from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticlePendingChangesPopover.vue';

import { useMapGetter } from 'dashboard/composables/store.js';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

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
  isSelected: {
    type: Boolean,
    default: false,
  },
  hasPendingChanges: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showSelectionControl: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'openArticle',
  'articleAction',
  'toggleSelect',
  'hover',
  'draftResolved',
  'draftFailed',
]);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const pendingChangesPopoverRef = useTemplateRef('pendingChangesPopoverRef');

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const { isEnterprise } = useConfig();

const isTranslationAvailable = computed(
  () =>
    isEnterprise &&
    isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CAPTAIN_TASKS
    )
);

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
  )
    .filter(key => key !== 'translate' || isTranslationAvailable.value)
    .map(key => commonItems[key]);

  const draftItems = props.hasPendingChanges
    ? [
        {
          label: t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.DISCARD_CHANGES'),
          value: 'discard-draft',
          action: 'discard-draft',
          icon: 'i-lucide-undo-2',
        },
      ]
    : [];

  return [...statusItems, ...draftItems, commonItems.delete];
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
  // Un-publishing an article with staged edits — confirm apply/discard first;
  // the popover applies the chosen status itself.
  if (props.hasPendingChanges && (action === 'draft' || action === 'archive')) {
    pendingChangesPopoverRef.value?.open(getArticleStatus(value));
    return;
  }
  emit('articleAction', { action, value, id: props.id });
};

const handleClick = id => {
  emit('openArticle', id);
};
</script>

<template>
  <CardLayout
    :selectable="selectable"
    class="relative"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div
      v-show="showSelectionControl"
      class="absolute top-7 ltr:left-3 rtl:right-3"
    >
      <Checkbox :model-value="isSelected" @change="emit('toggleSelect', id)" />
    </div>
    <div class="flex justify-between w-full gap-1">
      <div class="flex items-center gap-2 min-w-0">
        <span
          class="text-base cursor-pointer hover:underline underline-offset-2 hover:text-n-blue-11 text-n-slate-12 line-clamp-1"
          @click="handleClick(id)"
        >
          {{ title }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <span
          v-if="hasPendingChanges"
          :title="
            t(
              'HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.PENDING_EDITS_TOOLTIP'
            )
          "
          class="text-xs font-medium inline-flex items-center gap-1 h-6 px-2 py-0.5 rounded-md text-n-slate-11 bg-n-alpha-2 whitespace-nowrap shrink-0"
        >
          <span class="rounded-full size-1.5 bg-n-amber-9 shrink-0" />
          {{ t('HELP_CENTER.ARTICLES_PAGE.ARTICLE_CARD.CARD.PENDING_EDITS') }}
        </span>
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
            class="mt-1 end-0 top-full w-40"
            @action="handleArticleAction($event)"
          />
          <ArticlePendingChangesPopover
            ref="pendingChangesPopoverRef"
            :article-id="id"
            @resolved="emit('draftResolved', $event)"
            @failed="emit('draftFailed', $event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-2 sm:gap-4">
      <div class="flex items-center min-w-0 gap-2 sm:gap-4">
        <div class="flex items-center min-w-0 gap-1">
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
        <span class="flex items-center min-w-0 gap-1 text-sm text-n-slate-11">
          <EmojiIcon
            v-if="category?.icon"
            :value="category.icon"
            :color="category.icon_color"
            class="flex-shrink-0 size-4"
          />
          <span class="truncate">{{ categoryName }}</span>
        </span>
        <div
          class="inline-flex items-center gap-1 text-n-slate-11 whitespace-nowrap shrink-0"
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
      <span class="text-sm text-n-slate-11 line-clamp-1 shrink-0">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
