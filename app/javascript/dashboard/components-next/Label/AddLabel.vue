<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  labelMenuItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['updateLabel']);

const { t } = useI18n();

const showDropdown = ref(false);
</script>

<template>
  <div class="relative">
    <button
      class="flex items-center gap-1 px-2 py-1 rounded-md outline-dashed h-[26px] outline-1 outline-n-slate-6 hover:bg-n-alpha-2"
      :class="{ 'bg-n-alpha-2': showDropdown }"
      @click="showDropdown = !showDropdown"
    >
      <span class="i-lucide-plus" />
      <span class="text-sm text-n-slate-11">
        {{ t('LABEL.TAG_BUTTON') }}
      </span>
    </button>
    <DropdownMenu
      v-if="showDropdown"
      v-on-clickaway="() => (showDropdown = false)"
      :menu-items="labelMenuItems"
      show-search
      class="z-[100] w-48 mt-2 overflow-y-auto ltr:left-0 rtl:right-0 top-full max-h-52"
      @action="emit('updateLabel', $event)"
    >
      <template #thumbnail="{ item }">
        <div
          class="rounded-sm size-2"
          :style="{ backgroundColor: item.thumbnail.color }"
        />
      </template>
    </DropdownMenu>
  </div>
</template>
