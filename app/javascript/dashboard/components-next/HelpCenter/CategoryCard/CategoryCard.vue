<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  articlesCount: {
    type: Number,
    required: true,
  },
  slug: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['click', 'action']);

const { t } = useI18n();

const isOpen = ref(false);

const categoryMenuItems = [
  {
    label: 'Edit',
    action: 'edit',
    value: 'edit',
    icon: 'edit',
  },
  {
    label: 'Delete',
    action: 'delete',
    value: 'delete',
    icon: 'delete',
  },
];

const categoryTitleWithIcon = computed(() => {
  return `${props.icon} ${props.title}`;
});

const description = computed(() => {
  return props.description ? props.description : 'No description added';
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action, value }) => {
  emit('action', { action, value, id: props.id });
  isOpen.value = false;
};
</script>

<template>
  <CardLayout>
    <template #header>
      <div class="flex gap-2">
        <div class="flex justify-between w-full gap-1">
          <div class="flex items-center justify-start gap-2">
            <span
              class="text-base cursor-pointer hover:underline underline-offset-2 hover:text-n-blue-text text-n-slate-12 line-clamp-1"
              @click="handleClick(slug)"
            >
              {{ categoryTitleWithIcon }}
            </span>
            <span
              class="inline-flex items-center justify-center h-6 px-2 py-1 text-xs text-center truncate border rounded-lg min-w-fit text-slate-500 w-fit border-slate-200 dark:border-slate-800 dark:text-slate-400"
            >
              {{
                t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.ARTICLES_COUNT', {
                  count: articlesCount,
                })
              }}
            </span>
          </div>
          <div class="relative group" @click.stop>
            <OnClickOutside @trigger="isOpen = false">
              <Button
                icon="i-lucide-ellipsis-vertical"
                color="slate"
                size="xs"
                class="rounded-md group-hover:bg-n-solid-2"
                @click="isOpen = !isOpen"
              />
              <DropdownMenu
                v-if="isOpen"
                :menu-items="categoryMenuItems"
                class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:left-0 xl:rtl:right-0 top-full z-60"
                @action="handleAction"
              />
            </OnClickOutside>
          </div>
        </div>
      </div>
    </template>
    <template #footer>
      <span
        class="text-sm line-clamp-3"
        :class="
          hasDescription
            ? 'text-slate-500 dark:text-slate-400'
            : 'text-slate-400 dark:text-slate-700'
        "
      >
        {{ description }}
      </span>
    </template>
  </CardLayout>
</template>
