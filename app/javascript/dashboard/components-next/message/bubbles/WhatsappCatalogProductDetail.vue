<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  item: { type: Object, required: true },
});

const { t } = useI18n();
const photoIndex = ref(0);
const gallery = ref(null);

const images = computed(() => props.item.imageUrls || []);

const showPhoto = step => {
  const total = images.value.length;
  const target = (photoIndex.value + step + total) % total;
  gallery.value.scrollTo({
    left: target * gallery.value.clientWidth,
    behavior: 'smooth',
  });
};

const onScroll = () => {
  const { scrollLeft, clientWidth } = gallery.value;
  if (clientWidth) photoIndex.value = Math.round(scrollLeft / clientWidth);
};
</script>

<template>
  <div class="flex flex-col">
    <div class="relative w-full shrink-0 bg-n-alpha-2">
      <div
        v-if="images.length"
        ref="gallery"
        class="flex overflow-x-auto snap-x snap-mandatory [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        data-test-id="catalog-gallery"
        @scroll="onScroll"
      >
        <img
          v-for="(image, index) in images"
          :key="image"
          :src="image"
          :alt="`${item.name} ${index + 1}`"
          loading="lazy"
          class="object-contain w-full shrink-0 snap-center aspect-[4/3]"
        />
      </div>
      <div
        v-else
        class="flex items-center justify-center aspect-[4/3] text-n-slate-10"
      >
        <span class="i-lucide-image size-10" />
      </div>
      <template v-if="images.length > 1">
        <span
          class="absolute px-2 py-0.5 text-white rounded-full text-label-small bottom-2 end-2 bg-n-alpha-black2"
          data-test-id="catalog-photo-indicator"
        >
          {{
            t('CONVERSATION.WHATSAPP_CATALOG.PHOTO_OF', {
              current: photoIndex + 1,
              total: images.length,
            })
          }}
        </span>
        <NextButton
          icon="i-lucide-chevron-left"
          slate
          faded
          sm
          :aria-label="t('CONVERSATION.WHATSAPP_CATALOG.PREVIOUS_PHOTO')"
          class="absolute -translate-y-1/2 start-2 top-1/2 !rounded-full max-sm:hidden"
          data-test-id="catalog-photo-prev"
          @click="showPhoto(-1)"
        />
        <NextButton
          icon="i-lucide-chevron-right"
          slate
          faded
          sm
          :aria-label="t('CONVERSATION.WHATSAPP_CATALOG.NEXT_PHOTO')"
          class="absolute -translate-y-1/2 end-2 top-1/2 !rounded-full max-sm:hidden"
          data-test-id="catalog-photo-next"
          @click="showPhoto(1)"
        />
      </template>
    </div>
    <div class="flex flex-col gap-2 py-4 min-w-0">
      <h3 class="break-words text-heading-3 text-n-slate-12">
        {{ item.name }}
      </h3>
      <p v-if="item.price" class="text-body-main text-n-slate-12">
        {{ item.price }}
      </p>
      <div v-if="item.description">
        <div class="text-label-small text-n-slate-11">
          {{ t('CONVERSATION.WHATSAPP_CATALOG.DESCRIPTION') }}
        </div>
        <p
          class="whitespace-pre-wrap break-words text-body-main text-n-slate-11"
        >
          {{ item.description }}
        </p>
      </div>
      <a
        v-if="item.url"
        :href="item.url"
        target="_blank"
        rel="noopener noreferrer"
        class="break-all text-body-main text-n-teal-10 hover:underline"
        data-test-id="catalog-detail-link"
      >
        {{ item.url }}
      </a>
    </div>
  </div>
</template>
