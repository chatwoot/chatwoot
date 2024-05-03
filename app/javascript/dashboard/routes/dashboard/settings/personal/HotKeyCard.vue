<template>
  <div
    class="flex flex-col gap-4 w-full h-fit sm:max-h-[220px] p-4 sm:max-w-[350px] rounded-md border border-solid border-ash-200"
    :class="{
      'border-primary-300 ': active,
    }"
    @click="$emit('click')"
  >
    <div class="flex flex-col gap-2 items-center w-full rounded-t-[5px]">
      <div class="flex items-center justify-between w-full gap-1">
        <div class="flex items-center text-base font-medium text-ash-900">
          {{ title }}
        </div>
        <input
          :checked="active"
          type="radio"
          :name="`hotkey-${title}`"
          class="shadow cursor-pointer grid place-items-center border-2 border-ash-200 appearance-none rounded-full w-5 h-5 checked:bg-primary-600 before:content-[''] before:bg-primary-600 before:border-4 before:rounded-full before:border-ash-25 checked:before:w-[18px] checked:before:h-[18px] checked:border checked:border-primary-600"
        />
      </div>
      <span class="text-ash-900 text-sm line-clamp-2 leading-[1.4] text-start">
        {{ description }}
      </span>
    </div>

    <div>
      <img
        :src="lightImage"
        :alt="`Light themed image for ${title}`"
        class="block object-cover w-full dark:hidden"
      />
      <img
        :src="darkImage"
        :alt="`Dark themed image for ${title}`"
        class="hidden object-cover w-full dark:block"
      />
    </div>
  </div>
</template>

<script setup>
defineProps({
  active: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  lightImage: {
    type: String,
    default: '',
  },
  darkImage: {
    type: String,
    default: '',
  },
});
</script>
