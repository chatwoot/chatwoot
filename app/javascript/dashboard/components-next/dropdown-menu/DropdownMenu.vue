<script setup>
import { defineProps, ref, defineEmits, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  menuItems: {
    type: Array,
    required: true,
    validator: value => {
      return value.every(item => item.action && item.value && item.label);
    },
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
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const searchInput = ref(null);
const searchQuery = ref('');

const filteredMenuItems = computed(() => {
  if (!searchQuery.value) return props.menuItems;

  return props.menuItems.filter(item =>
    item.label.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const handleAction = item => {
  const { action, value, ...rest } = item;
  emit('action', { action, value, ...rest });
};

onMounted(() => {
  if (searchInput.value && props.showSearch) {
    searchInput.value.focus();
  }
});
</script>

<template>
  <div
    class="bg-n-alpha-3 backdrop-blur-[100px] border-0 outline outline-1 outline-n-container absolute rounded-xl z-50 py-2 px-2 gap-2 flex flex-col min-w-[136px] shadow-lg"
  >
    <div v-if="showSearch" class="relative">
      <span class="absolute i-lucide-search size-3.5 top-2 left-3" />
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="search"
        :placeholder="
          searchPlaceholder || t('DROPDOWN_MENU.SEARCH_PLACEHOLDER')
        "
        class="reset-base w-full h-8 py-2 pl-10 pr-2 text-sm focus:outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
      />
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
          rounded-full
        />
      </slot>
      <Icon v-if="item.icon" :icon="item.icon" class="flex-shrink-0 size-3.5" />
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
      v-if="filteredMenuItems.length === 0"
      class="text-sm text-n-slate-11 px-2 py-1.5"
    >
      {{
        isSearching
          ? t('DROPDOWN_MENU.SEARCHING')
          : t('DROPDOWN_MENU.EMPTY_STATE')
      }}
    </div>
  </div>
</template>
