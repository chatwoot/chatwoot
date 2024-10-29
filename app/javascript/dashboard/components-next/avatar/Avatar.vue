<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { computed, ref, watch } from 'vue';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    required: true,
  },
  size: {
    type: Number,
    default: 32,
  },
  allowUpload: {
    type: Boolean,
    default: false,
  },
  roundedFull: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: null,
    validator: value => {
      if (!value) return true;
      return wootConstants.AVAILABILITY_STATUS_KEYS.includes(value);
    },
  },
});
const emit = defineEmits(['upload']);

const isImageValid = ref(true);

function invalidateCurrentImage() {
  isImageValid.value = false;
}

const initials = computed(() => {
  const splitNames = props.name.split(' ');

  if (splitNames.length > 1) {
    const firstName = splitNames[0];
    const lastName = splitNames[splitNames.length - 1];

    return firstName[0] + lastName[0];
  }

  const firstName = splitNames[0];
  return firstName[0];
});

watch(
  () => props.src,
  () => {
    isImageValid.value = true;
  }
);
</script>

<template>
  <span
    class="relative inline"
    :style="{
      width: `${size}px`,
      height: `${size}px`,
    }"
  >
    <slot name="badge" :size>
      <div
        class="rounded-full w-2.5 h-2.5 absolute z-20"
        :style="{
          top: `${size - 10}px`,
          left: `${size - 10}px`,
        }"
        :class="{
          'bg-n-teal-10': status === 'online',
          'bg-n-amber-10': status === 'busy',
          'bg-n-slate-10': status === 'offline',
        }"
      />
    </slot>
    <span
      role="img"
      class="inline-flex relative items-center justify-center object-cover overflow-hidden font-medium bg-woot-50 text-woot-500 group/avatar"
      :class="{
        'rounded-full': roundedFull,
        'rounded-xl': !roundedFull,
      }"
      :style="{
        width: `${size}px`,
        height: `${size}px`,
      }"
    >
      <img
        v-if="src && isImageValid"
        :src="src"
        :alt="name"
        @error="invalidateCurrentImage"
      />
      <span v-else>
        {{ initials }}
      </span>
      <div
        v-if="allowUpload"
        role="button"
        class="absolute inset-0 flex items-center justify-center invisible w-full h-full transition-all duration-500 ease-in-out opacity-0 rounded-xl dark:bg-slate-900/50 bg-slate-900/20 group-hover/avatar:visible group-hover/avatar:opacity-100"
        @click="emit('upload')"
      >
        <Icon
          icon="i-lucide-upload"
          class="text-white dark:text-white size-4"
        />
      </div>
    </span>
  </span>
</template>
