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
      'border-n-brand ': active,
    }"
  >
    <div class="flex flex-col gap-2 items-center w-full rounded-t-[5px]">
      <div class="grid grid-cols-[1fr_auto] items-center w-full gap-1">
        <div class="overflow-hidden text-heading-2 text-n-slate-12 text-start">
          <span class="block truncate">{{ title }}</span>
        </div>
        <input
          :checked="active"
          type="radio"
          :name="`hotkey-${title}`"
          class="shadow cursor-pointer grid place-items-center border-2 border-n-strong appearance-none rounded-full w-5 h-5 checked:bg-n-brand before:content-[''] before:bg-n-brand before:border-4 before:rounded-full before:border-n-strong checked:before:w-[18px] checked:before:h-[18px] checked:border checked:border-n-brand"
        />
      </div>
      <span class="text-n-slate-11 line-clamp-2 text-body-para text-start">
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
