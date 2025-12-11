<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const description = computed(() => {
  return props.description ? props.description : 'No description added';
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action }) => {
  emit('action', { action, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex items-start justify-between gap-3 group/categoryCard">
      <div
        class="size-10 rounded-[0.625rem] mt-1 outline outline-1 outline-n-weak flex items-center justify-center flex-shrink-0"
      >
        <span v-if="icon" class="text-sm font-420">
          {{ icon }}
        </span>
        <Icon v-else icon="i-lucide-shapes" class="size-4 shrink-0" />
      </div>
      <div class="flex flex-col w-full gap-2">
        <div class="flex justify-between w-full gap-2 h-6">
          <div class="flex items-center justify-start min-w-0 gap-2">
            <span
              class="text-sm font-medium truncate group-hover/categoryCard:text-n-blue-11 cursor-pointer text-n-slate-12"
              @click="handleClick(slug)"
            >
              {{ title }}
            </span>
            <div class="w-px h-3 bg-n-weak rounded-lg shrink-0" />
            <span class="text-sm text-n-slate-11 font-420 shrink-0">
              {{
                t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.ARTICLES_COUNT', {
                  count: articlesCount,
                })
              }}
            </span>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <Button
              icon="i-lucide-pen-line"
              slate
              xs
              ghost
              class="[&>span]:size-3.5"
              @click="handleAction({ action: 'edit' })"
            />
            <div class="w-px h-3 bg-n-weak rounded-lg" />
            <Button
              icon="i-lucide-trash"
              slate
              xs
              ghost
              class="[&>span]:size-3.5"
              @click="handleAction({ action: 'delete' })"
            />
          </div>
        </div>

        <span
          class="text-sm line-clamp-3"
          :class="hasDescription ? 'text-n-slate-11' : 'text-n-slate-9'"
        >
          {{ description }}
        </span>
      </div>
    </div>
  </CardLayout>
</template>
