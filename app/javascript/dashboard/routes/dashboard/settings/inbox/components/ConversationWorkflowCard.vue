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
  radioName: {
    type: String,
    default: 'workflow-option',
  },
});
</script>

<template>
  <button
    class="px-0 w-full rounded-xl reset-base outline-1 outline"
    :class="active ? 'outline-n-brand/30' : 'outline-n-weak'"
  >
    <div
      class="flex flex-col gap-4 p-4 w-full rounded-md h-fit"
      :class="{
        'border-n-brand ': active,
      }"
    >
      <div class="flex flex-col gap-3 items-center w-full rounded-t-[5px]">
        <div class="grid grid-cols-[1fr_auto] items-center w-full gap-3">
          <div class="text-base font-medium text-left text-n-slate-12">
            <span class="block">{{ title }}</span>
          </div>
          <input
            :checked="active"
            type="radio"
            :name="radioName"
            class="shadow cursor-pointer grid place-items-center border-2 border-n-strong appearance-none rounded-full w-5 h-5 checked:bg-n-brand before:content-[''] before:bg-n-brand before:border-4 before:rounded-full before:border-n-strong checked:before:w-[18px] checked:before:h-[18px] checked:border checked:border-n-brand"
          />
        </div>
        <span class="w-full text-sm leading-relaxed text-n-slate-12 text-start">
          {{ description }}
        </span>
      </div>
    </div>
  </button>
</template>
