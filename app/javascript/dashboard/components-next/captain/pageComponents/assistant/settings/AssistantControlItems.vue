<script setup>
import { useRouter } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  controlItem: {
    type: Object,
    default: () => ({}),
  },
});

const router = useRouter();

const onClick = name => {
  router.push({ name });
};
</script>

<template>
  <div
    :key="controlItem.name"
    class="pt-3 ltr:pl-4 rtl:pr-4 ltr:pr-2 rtl:pl-2 pb-5 gap-2 flex flex-col w-full shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2 cursor-pointer"
    @click="onClick(controlItem.routeName)"
  >
    <div class="flex items-center justify-between w-full gap-1 h-8">
      <span class="text-sm font-medium text-n-slate-12 line-clamp-1">
        {{ controlItem.name }}
      </span>
      <div class="flex items-center gap-2">
        <Button
          icon="i-lucide-chevron-right"
          slate
          ghost
          xs
          @click="onClick(controlItem.routeName)"
        />
      </div>
    </div>
    <span class="text-n-slate-11 text-sm leading-[21px] line-clamp-5">
      {{ controlItem.description }}
    </span>
  </div>
</template>
