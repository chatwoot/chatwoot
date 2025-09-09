<script setup>
import { computed, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { picoSearch } from '@scmmishra/pico-search';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add']);

const [showPopover, togglePopover] = useToggle();

const searchValue = ref('');

const filteredItems = computed(() => {
  if (!searchValue.value) return props.items;
  const query = searchValue.value.toLowerCase();

  return picoSearch(props.items, query, ['name']);
});

const handleAdd = inbox => {
  emit('add', inbox);
  togglePopover(false);
};
</script>

<template>
  <div
    v-on-clickaway="() => togglePopover(false)"
    class="relative flex items-center group"
  >
    <Button
      slate
      type="button"
      icon="i-lucide-plus"
      sm
      :label="label"
      @click="togglePopover(!showPopover)"
    />
    <div
      v-if="showPopover"
      class="top-full mt-1 ltr:left-0 rtl:right-0 z-50 flex flex-col items-start absolute bg-n-alpha-3 backdrop-blur-[50px] border-0 gap-4 outline outline-1 outline-n-weak rounded-xl max-w-96 min-w-80 max-h-[20rem] overflow-y-auto py-2"
    >
      <div class="flex flex-col divide-y divide-n-slate-4 w-full">
        <Input
          v-model="searchValue"
          :placeholder="searchPlaceholder"
          custom-input-class="bg-transparent !outline-none w-full ltr:!pl-10 rtl:!pr-10 h-10"
        >
          <template #prefix>
            <Icon
              icon="i-lucide-search"
              class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-3 rtl:right-3"
            />
          </template>
        </Input>

        <div
          v-for="item in filteredItems"
          :key="item.id"
          class="flex items-start gap-3 min-w-0 w-full py-4 px-3 hover:bg-n-alpha-2 cursor-pointer"
          @click="handleAdd(item)"
        >
          <Icon
            v-if="item.icon"
            :icon="item.icon"
            class="size-4 text-n-slate-12 flex-shrink-0 mt-0.5"
          />
          <div class="flex flex-col items-start gap-2 min-w-0">
            <div class="flex items-center gap-1 min-w-0">
              <span
                :title="item.name"
                class="text-sm text-n-slate-12 truncate min-w-0"
              >
                {{ item.name }}
              </span>
              <span
                v-if="item.id"
                class="text-xs text-n-slate-11 flex-shrink-0"
              >
                {{ `#${item.id}` }}
              </span>
            </div>
            <span
              v-if="item.email || item.phoneNumber"
              class="text-sm text-n-slate-11 truncate min-w-0"
            >
              {{ item.email || item.phoneNumber }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
