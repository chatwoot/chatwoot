<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { toPng } from 'html-to-image';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  slideElement: {
    type: Object,
    default: null,
  },
  slideBackground: {
    type: String,
    required: true,
  },
  year: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const isGenerating = ref(false);
const shareImageUrl = ref(null);

const generateImage = async () => {
  if (!props.slideElement) return;

  isGenerating.value = true;
  try {
    let slideElement = props.slideElement;

    if (slideElement && '$el' in slideElement) {
      slideElement = slideElement.$el;
    }

    if (!slideElement) {
      // eslint-disable-next-line no-console
      console.error('No slide element found');
      return;
    }

    const colorMap = {
      'bg-[#5BD58A]': '#5BD58A',
      'bg-[#60a5fa]': '#60a5fa',
      'bg-[#fb923c]': '#fb923c',
      'bg-[#f87171]': '#f87171',
      'bg-[#fbbf24]': '#fbbf24',
    };
    const bgColor = colorMap[props.slideBackground] || '#ffffff';

    const dataUrl = await toPng(slideElement, {
      pixelRatio: 1.2,
      backgroundColor: bgColor,
      // Skip font/CSS embedding to avoid CORS issues with CDN stylesheets
      // See: https://github.com/bubkoo/html-to-image/issues/49#issuecomment-762222100
      fontEmbedCSS: '',
      cacheBust: true,
    });

    const img = new Image();
    img.src = dataUrl;
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
    });

    const finalCanvas = document.createElement('canvas');
    const borderSize = 20;
    const bottomPadding = 50;

    finalCanvas.width = img.width + borderSize * 2;
    finalCanvas.height = img.height + borderSize * 2 + bottomPadding;

    const ctx = finalCanvas.getContext('2d');

    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, finalCanvas.width, finalCanvas.height);

    ctx.drawImage(img, borderSize, borderSize);

    ctx.fillStyle = '#1f2d3d';
    ctx.font = 'normal 16px system-ui, -apple-system, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(
      t('YEAR_IN_REVIEW.SHARE_MODAL.BRANDING'),
      borderSize,
      img.height + borderSize + 35
    );

    const logo = new Image();
    logo.src = '/brand-assets/logo.svg';
    await new Promise(resolve => {
      logo.onload = resolve;
    });

    const logoHeight = 30;
    const logoWidth = (logo.width / logo.height) * logoHeight;
    const logoX = finalCanvas.width - borderSize - logoWidth;
    const logoY = img.height + borderSize + 15;

    ctx.drawImage(logo, logoX, logoY, logoWidth, logoHeight);

    shareImageUrl.value = finalCanvas.toDataURL('image/png');
  } catch (err) {
    // Handle errors silently for now
    // eslint-disable-next-line no-console
    console.error('Failed to generate image:', err);
  } finally {
    isGenerating.value = false;
  }
};

const downloadImage = () => {
  if (!shareImageUrl.value) return;

  const link = document.createElement('a');
  link.href = shareImageUrl.value;
  link.download = `chatwoot-year-in-review-${props.year}.png`;
  link.click();
};

const shareImage = async () => {
  if (!shareImageUrl.value) return;

  try {
    const response = await fetch(shareImageUrl.value);
    const blob = await response.blob();
    const file = new File([blob], `chatwoot-year-in-review-${props.year}.png`, {
      type: 'image/png',
    });

    if (
      navigator.share &&
      navigator.canShare &&
      navigator.canShare({ files: [file] })
    ) {
      await navigator.share({
        title: t('YEAR_IN_REVIEW.SHARE_MODAL.SHARE_TITLE', {
          year: props.year,
        }),
        text: t('YEAR_IN_REVIEW.SHARE_MODAL.SHARE_TEXT', { year: props.year }),
        files: [file],
      });
      return;
    }

    downloadImage();
  } catch (err) {
    // Fallback to download if sharing fails
    downloadImage();
  }
};

const close = () => {
  shareImageUrl.value = null;
  emit('close');
};

const handleOpen = async () => {
  if (props.show && !shareImageUrl.value) {
    await generateImage();
  }
};

defineExpose({ handleOpen });
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-[10001]"
      @click="close"
    >
      <div v-if="isGenerating" class="flex items-center justify-center">
        <div class="text-center">
          <div
            class="inline-block w-12 h-12 border-4 rounded-full border-white border-t-transparent animate-spin"
          />
          <p class="mt-4 text-sm text-white">
            {{ t('YEAR_IN_REVIEW.SHARE_MODAL.PREPARING') }}
          </p>
        </div>
      </div>

      <div
        v-else-if="shareImageUrl"
        class="max-w-2xl w-full mx-4 flex flex-col gap-6 bg-slate-800 rounded-2xl p-6"
        @click.stop
      >
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-medium text-white">
            {{ t('YEAR_IN_REVIEW.SHARE_MODAL.TITLE') }}
          </h3>
          <button
            class="w-10 h-10 flex items-center justify-center rounded-full text-white hover:bg-white hover:bg-opacity-20 transition-colors"
            @click="close"
          >
            <i class="i-lucide-x w-6 h-6" />
          </button>
        </div>

        <div>
          <img
            :src="shareImageUrl"
            alt="Year in Review"
            class="w-full h-auto"
          />
        </div>

        <div class="flex gap-3">
          <button
            class="flex-[2] px-4 py-3 flex items-center justify-center gap-2 rounded-full text-white bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
            @click="downloadImage"
          >
            <i class="i-lucide-download w-5 h-5" />
            <span class="text-sm font-medium">{{
              t('YEAR_IN_REVIEW.SHARE_MODAL.DOWNLOAD')
            }}</span>
          </button>

          <button
            class="w-10 h-10 flex items-center justify-center rounded-full text-white bg-white bg-opacity-20 hover:bg-opacity-30 transition-colors"
            @click="shareImage"
          >
            <i class="i-lucide-share-2 w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
