<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: { type: String, default: '' },
  note: { type: String, default: '' },
  videoUrl: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  fallbackThumbnail: { type: String, default: '' },
  fallbackThumbnailDark: { type: String, default: '' },
  learnMoreUrl: { type: String, default: '' },
});

const imageError = ref(false);

const handleImageError = () => {
  imageError.value = true;
};

const openLink = link => {
  if (link) {
    window.open(link, '_blank');
  }
};
</script>

<template>
  <section class="custom-dashed-border rounded-2xl py-5 px-6">
    <div class="flex flex-col md:flex-row items-start md:items-center gap-6">
      <div
        class="flex-shrink-0 bg-gray-800 w-[7.5rem] h-[6.5rem] rounded-lg flex items-center justify-center overflow-hidden"
      >
        <img
          v-if="!imageError && thumbnail"
          :src="thumbnail"
          :alt="title"
          draggable="false"
          class="w-full h-full object-cover rounded-lg"
          loading="lazy"
          @error="handleImageError"
        />

        <template v-else>
          <img
            v-if="fallbackThumbnailDark"
            :src="fallbackThumbnailDark"
            :alt="title"
            draggable="false"
            class="w-full h-full object-cover hidden dark:block rounded-lg"
            loading="lazy"
          />

          <img
            v-if="fallbackThumbnail"
            :src="fallbackThumbnail"
            :alt="title"
            draggable="false"
            class="w-full h-full object-cover block dark:hidden rounded-lg"
            loading="lazy"
          />
        </template>
      </div>

      <div class="flex flex-col flex-1 gap-3 ltr:pr-8 rtl:pl-8">
        <p v-if="note" class="text-n-slate-12 text-sm mb-0">{{ note }}</p>

        <div class="flex gap-3">
          <slot name="actions">
            <Button
              v-if="videoUrl"
              :label="$t('FEATURE_SPOTLIGHT.WATCH_VIDEO')"
              sm
              faded
              slate
              icon="i-lucide-circle-play"
              @click="openLink(videoUrl)"
            />

            <Button
              v-if="learnMoreUrl"
              :label="$t('FEATURE_SPOTLIGHT.LEARN_MORE')"
              sm
              faded
              slate
              trailing-icon
              icon="i-lucide-arrow-up-right"
              @click="openLink(learnMoreUrl)"
            />
          </slot>
        </div>
      </div>
    </div>
  </section>
</template>
