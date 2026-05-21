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
  },
  menuSections: {
    type: Array,
    default: () => [],
  },
  thumbnailSize: {
    type: Number,
    default: 20,
  },
  roundedThumbnail: {
    type: Boolean,
    default: true,
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
  isLoading: {
    type: Boolean,
    default: false,
  },
  emptyStateMessage: {
    type: String,
    default: 'DROPDOWN_MENU.EMPTY_STATE',
  },
});

const emit = defineEmits(['action', 'search', 'empty']);

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
  emit('search', event.target.value);

  const isEmpty = hasSections.value
    ? filteredMenuSections.value.length === 0
    : filteredMenuItems.value.length === 0;

  if (isEmpty) emit('empty');
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
    class="bg-n-alpha-3 backdrop-blur-[100px] border-0 outline outline-1 outline-n-container absolute rounded-xl z-50 flex flex-col min-w-[136px] shadow-lg pt-2 overflow-hidden"
  >
    <div v-if="showSearch" class="relative shrink-0 px-2 mb-2">
      <span
        class="absolute i-lucide-search size-3.5 top-2 ltr:left-5 rtl:right-5"
      />
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="search"
        :placeholder="
          searchPlaceholder || t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')
        "
        class="reset-base w-full h-8 py-2 ltr:pl-10 ltr:pr-2 rtl:pl-2 rtl:pr-10 text-sm focus:outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        @input="handleSearchInput"
      />
    </div>
    <div class="flex flex-col gap-2 overflow-y-auto min-h-0 px-2 pb-2">
      <template v-if="hasSections">
        <div
          v-for="(section, sectionIndex) in filteredMenuSections"
          :key="section.title || sectionIndex"
          class="flex flex-col gap-1"
        >
          <p
            v-if="section.title"
            class="px-2 py-2 text-xs mb-0 font-medium text-n-slate-11 uppercase tracking-wide sticky top-0 z-10 bg-n-alpha-3 backdrop-blur-sm"
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
                :rounded-full="roundedThumbnail"
              />
            </slot>
            <slot name="icon" :item="item">
              <Icon
                v-if="item.icon"
                :icon="item.icon"
                class="flex-shrink-0 size-3.5"
              />
            </slot>
            <span v-if="item.emoji" class="flex-shrink-0">{{
              item.emoji
            }}</span>
            <slot name="label" :item="item">
              <span
                v-if="item.label"
                class="min-w-0 text-sm font-420 truncate"
                :class="labelClass"
              >
                {{ item.label }}
              </span>
            </slot>
            <slot name="trailing-icon" :item="item" />
          </button>
          <div
            v-if="sectionIndex < filteredMenuSections.length - 1"
            class="h-px bg-n-alpha-2 mx-2 my-1"
          />
        </div>
      </template>
      <template v-else>
        <div v-if="isLoading" class="flex items-center justify-center py-2">
          <Spinner :size="24" />
        </div>
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
              :rounded-full="roundedThumbnail"
            />
          </slot>
          <slot name="icon" :item="item">
            <Icon
              v-if="item.icon"
              :icon="item.icon"
              class="flex-shrink-0 size-3.5"
            />
          </slot>
          <span v-if="item.emoji" class="flex-shrink-0">{{ item.emoji }}</span>
          <slot name="label" :item="item">
            <span
              v-if="item.label"
              class="min-w-0 text-sm font-420 truncate"
              :class="labelClass"
            >
              {{ item.label }}
            </span>
          </slot>
          <slot name="trailing-icon" :item="item" />
        </button>
      </template>
      <div
        v-if="shouldShowEmptyState"
        class="text-sm text-n-slate-11 px-2 py-1.5"
      >
        {{
          isSearching
            ? t('DROPDOWN_MENU.SEARCHING')
            : searchQuery
              ? t('DROPDOWN_MENU.EMPTY_STATE')
              : t(emptyStateMessage)
        }}
      </div>
    </div>
    <div v-if="$slots.footer" class="shrink-0">
      <slot name="footer" />
    </div>
  </div>
</template>
