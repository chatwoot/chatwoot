<script setup>
import { ref } from 'vue';
import { onClickOutside } from '@vueuse/core';
import V4Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  options: {
    type: Array,
    required: true,
  },
  size: {
    type: String,
    default: 'sm',
  },
  icon: {
    type: String,
    default: 'i-ph-download-simple',
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const dropdownRef = ref(null);
const showDropdown = ref(false);

const toggleDropdown = () => {
  if (!props.loading) {
    showDropdown.value = !showDropdown.value;
  }
};

const closeDropdown = () => {
  showDropdown.value = false;
};

onClickOutside(dropdownRef, closeDropdown);

const handleSelect = value => {
  emit('select', value);
  closeDropdown();
};
</script>

<template>
  <div ref="dropdownRef" class="relative inline-block">
    <V4Button
      :label="label"
      :icon="icon"
      :size="size"
      :loading="loading"
      :disabled="loading"
      @click="toggleDropdown"
    >
      <template v-if="!loading" #suffix>
        <i
          class="text-sm transition-transform duration-200 i-ph-caret-down"
          :class="[showDropdown ? 'rotate-180' : '']"
        />
      </template>
    </V4Button>

    <Transition
      enter-active-class="transition-all duration-150 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition-all duration-150 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 -translate-y-2"
    >
      <div
        v-if="showDropdown && !loading"
        class="absolute right-0 mt-1 w-full min-w-full rounded-lg border border-n-container bg-n-solid-2 shadow-lg z-50 overflow-hidden"
      >
        <button
          v-for="option in options"
          :key="option.value"
          class="flex items-center gap-2 w-full px-3 py-2 text-sm text-n-slate-12 hover:bg-n-container transition-colors duration-150 border-b border-n-container last:border-b-0 focus:outline-none focus:bg-n-container"
          @click="handleSelect(option.value)"
        >
          <i
            v-if="option.icon"
            class="text-base text-n-slate-11"
            :class="[option.icon]"
          />
          <span class="flex-1 text-left">{{ option.label }}</span>
        </button>
      </div>
    </Transition>
  </div>
</template>
