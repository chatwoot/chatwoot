<script setup>
import { computed, useTemplateRef } from 'vue';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';

const [isOpen, toggleOpen] = useToggle(false);
const changelogCard = useTemplateRef('changelogCard');

const isLoading = computed(() => changelogCard.value?.isLoading || false);
const hasArticles = computed(
  () => changelogCard.value?.unDismissedPosts?.length > 0
);
const shouldShowButton = computed(() => !isLoading.value && hasArticles.value);

const closePopover = () => {
  if (isOpen.value) {
    toggleOpen(false);
  }
};
</script>

<template>
  <div v-on-click-outside="closePopover" class="relative mb-2">
    <Button
      v-if="shouldShowButton"
      icon="i-lucide-sparkles"
      ghost
      slate
      :class="{ '!bg-n-alpha-2 dark:!bg-n-slate-9/30': isOpen }"
      @click="toggleOpen()"
    />

    <!-- Always render card so it can fetch data, control visibility with v-show -->
    <div
      v-show="isOpen && hasArticles"
      class="absolute ltr:left-full rtl:right-full bottom-0 ltr:ml-4 rtl:mr-4 z-40 bg-transparent w-52"
    >
      <SidebarChangelogCard
        ref="changelogCard"
        class="[&>div]:!pb-0 [&>div]:!px-0 rounded-lg"
      />
    </div>
  </div>
</template>
