<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="rounded-xl divide-y bg-n-alpha-2 divide-n-strong text-n-slate-12 max-w-80"
  >
    <div class="px-3 py-2.5">
      <img :src="message.image_url" class="w-full max-h-44 rounded-lg" />
      <div class="flex flex-col gap-2 pt-2.5">
        <h6 class="font-semibold">{{ message.title }}</h6>
        <span
          v-dompurify-html="message.content"
          class="text-sm prose prose-bubble"
        />
      </div>
    </div>
    <div class="flex justify-center items-center p-3">
      <Button label="Call us to order" link class="hover:!no-underline" />
    </div>
    <div class="flex justify-center items-center p-3">
      <Button label="Visit our store" link class="hover:!no-underline" />
    </div>
  </div>
</template>
