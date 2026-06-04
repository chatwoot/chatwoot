<script setup>
import { computed, ref } from 'vue';

const props = defineProps({
  preview: {
    type: Object,
    required: true,
  },
});

const previewUrl = computed(() => props.preview.url);
const imageUrl = computed(
  () => props.preview.imageUrl || props.preview.image_url
);
const faviconUrl = computed(
  () => props.preview.faviconUrl || props.preview.favicon_url
);
const siteName = computed(
  () => props.preview.siteName || props.preview.site_name
);
const imageFailed = ref(false);

const primaryVisualUrl = computed(() => {
  if (!imageFailed.value && imageUrl.value) {
    return imageUrl.value;
  }

  return faviconUrl.value;
});

const showFavicon = computed(() => {
  return !imageUrl.value || imageFailed.value;
});

const displayHost = computed(() => {
  if (siteName.value) return siteName.value;

  try {
    return new URL(previewUrl.value).host;
  } catch {
    return previewUrl.value;
  }
});

const handleImageError = () => {
  imageFailed.value = true;
};
</script>

<template>
  <a
    :href="previewUrl"
    target="_blank"
    rel="noreferrer noopener nofollow"
    class="flex max-w-[22rem] overflow-hidden rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 no-underline transition-colors hover:bg-n-alpha-3"
  >
    <div
      class="flex h-24 w-24 shrink-0 items-center justify-center bg-n-alpha-3"
    >
      <img
        v-if="primaryVisualUrl"
        :src="primaryVisualUrl"
        alt=""
        :class="
          showFavicon
            ? 'h-8 w-8 rounded object-contain'
            : 'h-24 w-24 object-cover'
        "
        loading="lazy"
        @error="handleImageError"
      />
    </div>
    <div class="flex min-w-0 flex-col gap-1 px-3 py-2">
      <span
        v-if="displayHost"
        class="truncate text-xs font-medium uppercase text-n-slate-11"
      >
        {{ displayHost }}
      </span>
      <span
        v-if="preview.title"
        class="line-clamp-2 text-sm font-medium leading-5 text-n-slate-12"
      >
        {{ preview.title }}
      </span>
      <span
        v-if="preview.description"
        class="line-clamp-2 text-xs leading-4 text-n-slate-11"
      >
        {{ preview.description }}
      </span>
    </div>
  </a>
</template>
