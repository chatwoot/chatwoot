<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { buildLocaleMenuItems } from 'dashboard/helper/portalHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  locale: {
    type: String,
    required: true,
  },
  isDefault: {
    type: Boolean,
    required: true,
  },
  isDraft: {
    type: Boolean,
    required: true,
  },
  localeCode: {
    type: String,
    required: true,
  },
  articleCount: {
    type: Number,
    required: true,
  },
  categoryCount: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showDropdownMenu, toggleDropdown] = useToggle();

const localeLabel = computed(() => `${props.locale} (${props.localeCode})`);

const localeMenuLabels = computed(() => ({
  'change-default': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.MAKE_DEFAULT'
  ),
  'move-to-draft': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.MOVE_TO_DRAFT'
  ),
  'publish-locale': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.PUBLISH_LOCALE'
  ),
  delete: t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.DELETE'),
}));

const localeMenuItems = computed(() =>
  buildLocaleMenuItems({
    isDefault: props.isDefault,
    isDraft: props.isDraft,
  }).map(item => ({
    ...item,
    label: localeMenuLabels.value[item.action],
  }))
);

const handleAction = ({ action, value }) => {
  emit('action', { action, value });
  toggleDropdown(false);
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between gap-2">
      <div class="flex items-center justify-start gap-2">
        <span class="text-sm font-medium text-n-slate-12 line-clamp-1">
          {{ localeLabel }}
        </span>
        <span
          v-if="isDefault"
          class="bg-n-alpha-2 h-6 inline-flex items-center justify-center rounded-md text-xs border-px border-transparent text-n-blue-11 px-2 py-0.5"
        >
          {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DEFAULT') }}
        </span>
        <span
          v-else-if="isDraft"
          class="bg-n-alpha-2 h-6 inline-flex items-center justify-center rounded-md text-xs border-px border-transparent text-n-slate-11 px-2 py-0.5"
        >
          {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DRAFT') }}
        </span>
      </div>
      <div class="flex items-center justify-end gap-4">
        <div class="flex items-center gap-4">
          <span class="text-sm text-n-slate-11 whitespace-nowrap">
            {{
              $t(
                'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.ARTICLES_COUNT',
                articleCount
              )
            }}
          </span>
          <div class="w-px h-3 bg-n-weak" />
          <span class="text-sm text-n-slate-11 whitespace-nowrap">
            {{
              $t(
                'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.CATEGORIES_COUNT',
                categoryCount
              )
            }}
          </span>
        </div>
        <div
          v-if="localeMenuItems.length"
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />

          <DropdownMenu
            v-if="showDropdownMenu"
            :menu-items="localeMenuItems"
            class="ltr:right-0 rtl:left-0 mt-1 xl:ltr:left-0 xl:rtl:right-0 top-full z-60 min-w-[150px]"
            @action="handleAction"
          />
        </div>
      </div>
    </div>
  </CardLayout>
</template>
