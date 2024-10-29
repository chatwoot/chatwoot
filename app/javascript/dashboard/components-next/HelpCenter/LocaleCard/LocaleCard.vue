<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { LOCALE_MENU_ITEMS } from 'dashboard/helper/portalHelper';

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

const showDropdownMenu = ref(false);

const localeMenuItems = computed(() =>
  LOCALE_MENU_ITEMS.map(item => ({
    ...item,
    label: t(item.label),
    disabled: props.isDefault,
  }))
);

const handleAction = ({ action, value }) => {
  emit('action', { action, value });
  showDropdownMenu.value = false;
};
</script>

<template>
  <CardLayout class="ltr:pr-2 rtl:pl-2">
    <template #header>
      <div class="flex justify-between gap-2">
        <div class="flex items-center justify-start gap-2">
          <span
            class="text-sm font-medium text-slate-900 dark:text-slate-50 line-clamp-1"
          >
            {{ locale }} ({{ localeCode }})
          </span>
          <span
            v-if="isDefault"
            class="bg-slate-100 dark:bg-slate-800 h-6 inline-flex items-center justify-center rounded-md text-xs border-px border-transparent text-woot-500 dark:text-woot-400 px-2 py-0.5"
          >
            {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DEFAULT') }}
          </span>
        </div>
        <div class="flex items-center justify-end gap-2">
          <div class="flex items-center gap-4">
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              {{
                $t(
                  'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.ARTICLES_COUNT',
                  articleCount
                )
              }}
            </span>
            <div class="w-px h-3 bg-slate-75 dark:bg-slate-800" />
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              {{
                $t(
                  'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.CATEGORIES_COUNT',
                  categoryCount
                )
              }}
            </span>
          </div>
          <div class="relative group">
            <OnClickOutside @trigger="showDropdownMenu = false">
              <Button
                variant="ghost"
                size="sm"
                icon="more-vertical"
                class="w-8 group-hover:bg-slate-100 dark:group-hover:bg-slate-800"
                @click="showDropdownMenu = !showDropdownMenu"
              />

              <DropdownMenu
                v-if="showDropdownMenu"
                :menu-items="localeMenuItems"
                class="ltr:right-0 rtl:left-0 mt-1 xl:ltr:left-0 xl:rtl:right-0 top-full z-60 min-w-[150px]"
                @action="handleAction"
              />
            </OnClickOutside>
          </div>
        </div>
      </div>
    </template>
  </CardLayout>
</template>
