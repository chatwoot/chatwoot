<script setup>
import { computed, ref } from 'vue';
import { useToggle, useWindowSize, useElementBounding } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { picoSearch } from '@scmmishra/pico-search';

import Avatar from 'next/avatar/Avatar.vue';
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

const BUFFER_SPACE = 20;

const [showPopover, togglePopover] = useToggle();
const buttonRef = ref();
const dropdownRef = ref();

const searchValue = ref('');

const { width: windowWidth, height: windowHeight } = useWindowSize();
const {
  top: buttonTop,
  left: buttonLeft,
  width: buttonWidth,
  height: buttonHeight,
} = useElementBounding(buttonRef);
const { width: dropdownWidth, height: dropdownHeight } =
  useElementBounding(dropdownRef);

const filteredItems = computed(() => {
  if (!searchValue.value) return props.items;
  const query = searchValue.value.toLowerCase();

  return picoSearch(props.items, query, ['name']);
});

const handleAdd = item => {
  emit('add', item);
  togglePopover(false);
};

const shouldShowAbove = computed(() => {
  if (!buttonRef.value || !dropdownRef.value) return false;
  const spaceBelow =
    windowHeight.value - (buttonTop.value + buttonHeight.value);
  const spaceAbove = buttonTop.value;
  return (
    spaceBelow < dropdownHeight.value + BUFFER_SPACE && spaceAbove > spaceBelow
  );
});

const shouldAlignRight = computed(() => {
  if (!buttonRef.value || !dropdownRef.value) return false;
  const spaceRight = windowWidth.value - buttonLeft.value;
  const spaceLeft = buttonLeft.value + buttonWidth.value;

  return (
    spaceRight < dropdownWidth.value + BUFFER_SPACE && spaceLeft > spaceRight
  );
});

const handleClickOutside = () => {
  if (showPopover.value) {
    togglePopover(false);
  }
};
</script>

<template>
  <div
    v-on-click-outside="handleClickOutside"
    class="relative flex items-center group"
  >
    <Button
      ref="buttonRef"
      slate
      type="button"
      icon="i-lucide-plus"
      sm
      :label="label"
      @click="togglePopover(!showPopover)"
    />
    <div
      v-if="showPopover"
      ref="dropdownRef"
      class="z-50 flex flex-col items-start absolute bg-n-alpha-3 backdrop-blur-[50px] border-0 gap-4 outline outline-1 outline-n-weak rounded-xl max-w-96 min-w-80 max-h-[20rem] overflow-y-auto py-2"
      :class="[
        shouldShowAbove ? 'bottom-full mb-2' : 'top-full mt-2',
        shouldAlignRight ? 'right-0' : 'left-0',
      ]"
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
          class="flex gap-3 min-w-0 w-full py-4 px-3 hover:bg-n-alpha-2 cursor-pointer"
          :class="{ 'items-center': item.color, 'items-start': !item.color }"
          @click="handleAdd(item)"
        >
          <Icon
            v-if="item.icon"
            :icon="item.icon"
            class="size-4 text-n-slate-12 flex-shrink-0 mt-0.5"
          />
          <span
            v-else-if="item.color"
            :style="{ backgroundColor: item.color }"
            class="size-3 rounded-sm"
          />
          <Avatar
            v-else
            :title="item.name"
            :src="item.avatarUrl"
            :name="item.name"
            :size="20"
            rounded-full
          />
          <div class="flex flex-col items-start gap-2 min-w-0 flex-1">
            <div class="flex items-center gap-1 min-w-0 w-full">
              <span
                :title="item.name || item.title"
                class="text-sm text-n-slate-12 truncate min-w-0 flex-1"
              >
                {{ item.name || item.title }}
              </span>
            </div>
            <span
              v-if="item.email || item.phoneNumber"
              :title="item.email || item.phoneNumber"
              class="text-sm text-n-slate-11 truncate min-w-0 w-full block"
            >
              {{ item.email || item.phoneNumber }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
