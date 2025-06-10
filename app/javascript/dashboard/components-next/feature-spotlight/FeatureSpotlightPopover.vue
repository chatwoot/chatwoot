<script setup>
import { ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  buttonLabel: { type: String, default: '' },
  title: { type: String, default: '' },
  note: { type: String, default: '' },
  videoUrl: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  fallbackThumbnail: { type: String, default: '' },
  fallbackThumbnailDark: { type: String, default: '' },
  learnMoreUrl: { type: String, default: '' },
});

const imageError = ref(false);
const [isPopupVisible, togglePopup] = useToggle();

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
  <div class="relative">
    <Button
      id="togglePopup"
      :label="buttonLabel"
      slate
      ghost
      sm
      :class="{ 'bg-n-alpha-2': isPopupVisible }"
      @click="togglePopup(!isPopupVisible)"
    />

    <div
      v-if="isPopupVisible"
      v-on-click-outside="[
        () => isPopupVisible && (isPopupVisible = false),
        { ignore: ['#togglePopup'] },
      ]"
    >
      <section
        class="absolute top-full mt-6 ltr:left-0 rtl:right-0 outline outline-1 outline-n-weak bg-n-alpha-3 backdrop-blur-[100px] rounded-xl p-4 w-80"
      >
        <div
          class="absolute -top-[0.77rem] ltr:left-12 rtl:right-12 w-6 h-6 ltr:rotate-45 rtl:-rotate-45 rtl:rounded-tr ltr:rounded-tl rtl:border-r ltr:border-l border-t border-n-weak bg-n-alpha-3 z-10"
        />

        <div class="relative flex flex-col items-start gap-4 z-20">
          <div class="flex-shrink-0 bg-gray-800 w-full h-[7.5rem] rounded-lg">
            <img
              v-if="!imageError && thumbnail"
              :src="thumbnail"
              :alt="title"
              draggable="false"
              loading="lazy"
              class="w-full h-full object-cover rounded-lg"
              @error="handleImageError"
            />

            <template v-else>
              <img
                v-if="fallbackThumbnailDark"
                :src="fallbackThumbnailDark"
                :alt="title"
                draggable="false"
                loading="lazy"
                class="w-full h-full object-cover hidden dark:block"
              />

              <img
                v-if="fallbackThumbnail"
                :src="fallbackThumbnail"
                :alt="title"
                draggable="false"
                loading="lazy"
                class="w-full h-full object-cover block dark:hidden"
              />
            </template>
          </div>

          <p v-if="note" class="text-n-slate-12 text-start text-sm mb-0">
            {{ note }}
          </p>

          <div class="flex gap-3 justify-between w-full">
            <slot name="actions">
              <Button
                v-if="videoUrl"
                :label="$t('FEATURE_SPOTLIGHT.WATCH_VIDEO')"
                sm
                faded
                slate
                icon="i-lucide-circle-play"
                class="w-full"
                @click="openLink(videoUrl)"
              />

              <Button
                v-if="learnMoreUrl"
                :label="$t('FEATURE_SPOTLIGHT.LEARN_MORE')"
                sm
                faded
                slate
                trailing-icon
                class="w-full"
                icon="i-lucide-arrow-up-right"
                @click="openLink(learnMoreUrl)"
              />
            </slot>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>
