<template>
  <div
    class="flex flex-col gap-4 w-full h-[220px] md:max-h-[220px] p-4 md:w-[350px] rounded-md border border-solid border-ash-200"
    :class="{
      'border border-solid border-primary-300 ': active,
    }"
  >
    <div class="flex flex-col gap-2 items-center w-full rounded-t-[5px]">
      <div class="flex items-center justify-between w-full gap-1">
        <div class="flex items-center text-base font-medium text-ash-900">
          {{ heading }}
        </div>
        <input
          :checked="active"
          type="radio"
          name="hotkey"
          @change="$emit('update', 'enter')"
        />
      </div>
      <span class="text-ash-900 text-sm leading-[1.4] text-start">
        {{ content }}
      </span>
    </div>

    <div v-if="src">
      <img :src="src" class="object-cover w-full" />
    </div>
    <slot v-else />
  </div>
</template>

<script setup>
defineProps({
  active: {
    type: Boolean,
    default: false,
  },
  heading: {
    type: String,
    default: '',
  },
  content: {
    type: String,
    default: '',
  },
  src: {
    type: String,
    default: '',
  },
});
</script>
