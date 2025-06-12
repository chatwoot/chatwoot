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

<template>
  <button
    class="flex flex-col gap-4 w-full h-fit p-4 rounded-md border border-n-weak dark:border-n-weak"
    :class="{
      'border-primary-300 ': active,
    }"
  >
    <div class="flex flex-col gap-2 items-center w-full rounded-t-[5px]">
      <div class="grid grid-cols-[1fr_auto] items-center w-full gap-1">
        <div
          class="overflow-hidden text-base font-medium text-ash-900 text-left"
        >
          <span class="block truncate">{{ title }}</span>
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
  </button>
</template>
