<script setup>
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  count: {
    type: Number,
    default: 0,
  },
  title: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['fetch']);

const [showPopover, togglePopover] = useToggle();

const handleButtonClick = () => {
  emit('fetch');
  togglePopover(!showPopover.value);
};

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
    <button
      v-if="count"
      class="h-6 px-2 rounded-md bg-n-alpha-2 gap-1.5 flex items-center"
      @click="handleButtonClick()"
    >
      <Icon :icon="icon" class="size-3.5 text-n-slate-12" />
      <span class="text-n-slate-12 text-sm">
        {{ count }}
      </span>
    </button>
    <div
      v-if="showPopover"
      class="top-full mt-1 ltr:left-0 rtl:right-0 z-50 flex flex-col items-start absolute bg-n-alpha-3 backdrop-blur-[50px] border-0 gap-4 outline outline-1 outline-n-weak p-3 rounded-xl max-w-96 min-w-80 max-h-[20rem] overflow-y-auto"
    >
      <div class="flex items-center gap-2.5 pb-2">
        <Icon :icon="icon" class="size-3.5" />
        <span class="text-sm text-n-slate-12 font-medium">{{ title }}</span>
      </div>

      <div
        v-if="isFetching"
        class="flex items-center justify-center py-3 w-full text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else class="flex flex-col gap-4 w-full">
        <div
          v-for="item in items"
          :key="item.id"
          class="flex items-center justify-between gap-2 min-w-0 w-full"
        >
          <div class="flex items-center gap-2 min-w-0 w-full">
            <Icon
              v-if="item.icon"
              :icon="item.icon"
              class="size-4 text-n-slate-12 flex-shrink-0"
            />
            <Avatar
              v-else
              :title="item.name"
              :src="item.avatarUrl"
              :name="item.name"
              :size="20"
              rounded-full
            />
            <div class="flex items-center gap-1 min-w-0 flex-1">
              <span
                :title="item.name"
                class="text-sm text-n-slate-12 truncate min-w-0"
              >
                {{ item.name }}
              </span>
              <span
                v-if="item.id"
                class="text-sm text-n-slate-11 flex-shrink-0"
              >
                {{ `#${item.id}` }}
              </span>
            </div>
          </div>
          <span v-if="item.email" class="text-sm text-n-slate-11 flex-shrink-0">
            {{ item.email }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
