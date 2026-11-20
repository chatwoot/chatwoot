<script setup>
import { onMounted, ref } from 'vue';
import { logEvent } from 'histoire/client';
import ImageEditor from './ImageEditor.vue';

const screenshot = ref(null);
const phonePhoto = ref(null);
// Each variant shows its exported image after Send, to check what would be uploaded.
const saved = ref({});

// A fake page with text and a form, so blur, crop and the shapes have something to mark.
const drawSample = (width, height) => {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#f8fafc';
  ctx.fillRect(0, 0, width, height);
  ctx.fillStyle = '#1f93ff';
  ctx.fillRect(0, 0, width, height * 0.08);
  ctx.fillStyle = '#0f172a';
  ctx.font = `${Math.round(height / 25)}px sans-serif`;
  ctx.fillText('Checkout', width * 0.05, height * 0.2);
  ctx.font = `${Math.round(height / 40)}px sans-serif`;
  ctx.fillText('Card number: 4111 1111 1111 1111', width * 0.05, height * 0.3);
  ctx.fillText('Error: payment declined (code 51)', width * 0.05, height * 0.4);
  ctx.fillStyle = '#e2e8f0';
  ctx.fillRect(width * 0.05, height * 0.5, width * 0.6, height * 0.08);
  ctx.fillStyle = '#ef4444';
  ctx.fillRect(width * 0.05, height * 0.65, width * 0.25, height * 0.07);
  return new Promise(resolve => {
    canvas.toBlob(blob => {
      resolve(new File([blob], 'sample.png', { type: 'image/png' }));
    }, 'image/png');
  });
};

const onSave = (variant, file) => {
  logEvent('save', { name: file.name, type: file.type, size: file.size });
  saved.value = { ...saved.value, [variant]: URL.createObjectURL(file) };
};

onMounted(async () => {
  screenshot.value = await drawSample(1280, 800);
  phonePhoto.value = await drawSample(1080, 1920);
});
</script>

<template>
  <Story title="Widget/ImageEditor" :layout="{ type: 'single' }">
    <Variant title="Desktop screenshot">
      <img v-if="saved.desktop" :src="saved.desktop" class="max-w-full" />
      <ImageEditor
        v-else-if="screenshot"
        :file="screenshot"
        confirm-class="bg-n-brand text-white"
        @save="file => onSave('desktop', file)"
        @cancel="logEvent('cancel')"
      />
    </Variant>
    <Variant title="Phone photo">
      <img v-if="saved.phone" :src="saved.phone" class="max-w-full" />
      <ImageEditor
        v-else-if="phonePhoto"
        :file="phonePhoto"
        confirm-class="bg-n-amber-9 text-n-black"
        is-dark
        @save="file => onSave('phone', file)"
        @cancel="logEvent('cancel')"
      />
    </Variant>
  </Story>
</template>
