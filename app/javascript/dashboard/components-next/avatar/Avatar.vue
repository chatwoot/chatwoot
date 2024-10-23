<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { computed, ref, watch } from 'vue';

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
      <Icon icon="i-lucide-upload" class="text-white dark:text-white size-4" />
    </div>
  </span>
</template>
