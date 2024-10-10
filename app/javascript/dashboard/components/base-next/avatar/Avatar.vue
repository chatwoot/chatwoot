<script setup>
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
    type: String,
    default: 'medium',
    validate: value => ['large', 'medium', 'small', 'tiny'].includes(value),
  },
});

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
    class="inline-flex items-center justify-center object-cover overflow-hidden font-medium rounded-full bg-woot-50 text-woot-500"
    :class="{
      'w-12 h-12 text-lg': size === 'large',
      'w-8 h-8 text-sm': size === 'medium',
      'w-6 h-6 text-xs': size === 'small',
      'w-5 h-5 text-[0.625rem]': size === 'tiny',
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
  </span>
</template>
