<script setup>
import { defineProps, ref, defineEmits, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  menuItems: {
    type: Array,
    default: () => [],
    validator: value => {
      return value.every(item => item.action && item.value && item.label);
    },
  },
  menuSections: {
    type: Array,
    default: () => [],
  },
  thumbnailSize: {
    type: Number,
    default: 20,
  },
  showSearch: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  labelClass: {
    type: String,
    default: '',
  },
  disableLocalFiltering: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action', 'search']);

const { t } = useI18n();

const searchInput = ref(null);
const searchQuery = ref('');

const hasSections = computed(() => props.menuSections.length > 0);

const flattenedMenuItems = computed(() => {
  if (!hasSections.value) {
    return props.menuItems;
  }

  return props.menuSections.flatMap(section => section.items || []);
});

const filteredMenuItems = computed(() => {
  if (props.disableLocalFiltering) return props.menuItems;
  if (!searchQuery.value) return flattenedMenuItems.value;

  return flattenedMenuItems.value.filter(item =>
    item.label.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const filteredMenuSections = computed(() => {
  if (!hasSections.value) {
    return [];
  }

  if (props.disableLocalFiltering || !searchQuery.value) {
    return props.menuSections;
  }

  const query = searchQuery.value.toLowerCase();

  return props.menuSections
    .map(section => {
      const filteredItems = (section.items || []).filter(item =>
        item.label.toLowerCase().includes(query)
      );

      return {
        ...section,
        items: filteredItems,
      };
    })
    .filter(section => section.items.length > 0);
});

const handleSearchInput = event => {
  if (props.disableLocalFiltering) {
    emit('search', event.target.value);
  }
};

const handleAction = item => {
  const { action, value, ...rest } = item;
  emit('action', { action, value, ...rest });
};

const shouldShowEmptyState = computed(() => {
  if (hasSections.value) {
    return filteredMenuSections.value.length === 0;
  }

  return filteredMenuItems.value.length === 0;
});

onMounted(() => {
  if (searchInput.value && props.showSearch) {
    searchInput.value.focus();
  }
});
</script>

<template>
  <div
    class="bg-n-alpha-3 backdrop-blur-[100px] border-0 outline outline-1 outline-n-container absolute rounded-xl z-50 gap-2 flex flex-col min-w-[136px] shadow-lg pb-2 px-2"
    :class="{
      'pt-2': !showSearch,
    }"
  >
    <div
      v-if="showSearch"
      class="sticky top-0 bg-n-alpha-3 backdrop-blur-sm pt-2 z-20"
    >
      <div class="relative">
        <span class="absolute i-lucide-search size-3.5 top-2 left-3" />
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="search"
          :placeholder="
            searchPlaceholder || t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')
          "
          class="reset-base w-full h-8 py-2 pl-10 pr-2 text-sm focus:outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
          @input="handleSearchInput"
        />
      </div>
    </div>
    <template v-if="hasSections">
      <div
        v-for="(section, sectionIndex) in filteredMenuSections"
        :key="section.title || sectionIndex"
        class="flex flex-col gap-1"
      >
        <p
          v-if="section.title"
          class="px-2 py-2 text-xs mb-0 font-medium text-n-slate-11 uppercase tracking-wide sticky z-10 bg-n-alpha-3 backdrop-blur-sm"
          :class="showSearch ? 'top-10' : 'top-0'"
        >
          {{ section.title }}
        </p>
        <div
          v-if="section.isLoading"
          class="flex items-center justify-center py-2"
        >
          <Spinner :size="24" />
        </div>
        <div
          v-else-if="!section.items.length && section.emptyState"
          class="text-sm text-n-slate-11 px-2 py-1.5"
        >
          {{ section.emptyState }}
        </div>
        <button
          v-for="(item, itemIndex) in section.items"
          :key="item.value || itemIndex"
          type="button"
          class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 transition-all duration-200 ease-in-out border-0 rounded-lg z-60 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2 disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50"
          :class="{
            'bg-n-alpha-1 dark:bg-n-solid-active': item.isSelected,
            'text-n-ruby-11': item.action === 'delete',
            'text-n-slate-12': item.action !== 'delete',
          }"
          :disabled="item.disabled"
          @click="handleAction(item)"
        >
          <slot name="thumbnail" :item="item">
            <Avatar
              v-if="item.thumbnail"
              :name="item.thumbnail.name"
              :src="item.thumbnail.src"
              :size="thumbnailSize"
              rounded-full
            />
          </slot>
          <Icon
            v-if="item.icon"
            :icon="item.icon"
            class="flex-shrink-0 size-3.5"
          />
          <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
          <span
            v-if="item.label"
            class="min-w-0 text-sm truncate"
            :class="labelClass"
          >
            {{ item.label }}
          </span>
        </button>
        <div
          v-if="sectionIndex < filteredMenuSections.length - 1"
          class="h-px bg-n-alpha-2 mx-2 my-1"
        />
      </div>
    </template>
    <template v-else>
      <button
        v-for="(item, index) in filteredMenuItems"
        :key="index"
        type="button"
        class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 transition-all duration-200 ease-in-out border-0 rounded-lg z-60 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2 disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50"
        :class="{
          'bg-n-alpha-1 dark:bg-n-solid-active': item.isSelected,
          'text-n-ruby-11': item.action === 'delete',
          'text-n-slate-12': item.action !== 'delete',
        }"
        :disabled="item.disabled"
        @click="handleAction(item)"
      >
        <slot name="thumbnail" :item="item">
          <Avatar
            v-if="item.thumbnail"
            :name="item.thumbnail.name"
            :src="item.thumbnail.src"
            :size="thumbnailSize"
            rounded-full
          />
        </slot>
        <Icon
          v-if="item.icon"
          :icon="item.icon"
          class="flex-shrink-0 size-3.5"
        />
        <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
        <span
          v-if="item.label"
          class="min-w-0 text-sm truncate"
          :class="labelClass"
        >
          {{ item.label }}
        </span>
      </button>
    </template>
    <div
      v-if="shouldShowEmptyState"
      class="text-sm text-n-slate-11 px-2 py-1.5"
    >
      {{
        isSearching
          ? t('DROPDOWN_MENU.SEARCHING')
          : t('DROPDOWN_MENU.EMPTY_STATE')
      }}
    </div>
    <slot name="footer" />
  </div>
</template>
