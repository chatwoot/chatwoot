<script setup>
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import { useScroll, useSwipe } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { embeds } from 'dashboard/helper/markdownEmbeds';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const YOUTUBE_THUMBNAIL_URL =
  'https://i.ytimg.com/vi/%{video_id}/mqdefault.jpg';
const STRIP_SCROLL_RATIO = 0.8;
const MAX_PAGER_DOTS = 7;

const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');
const isRTL = useMapGetter('accounts/isRTL');
const { uiSettings, updateUISettings } = useUISettings();

const dialogRef = useTemplateRef('dialogRef');
const contentRef = useTemplateRef('contentRef');
const stripRef = useTemplateRef('stripRef');
const selectedId = ref(null);

const announcements = computed(
  () => globalConfig.value.activeFeatureAnnouncements
);

const dismissKey = ({ id, updated_at: updatedAt }) => `${id}-${updatedAt}`;

const withVideo = item => {
  const { key, regex, template } = embeds.find(embed =>
    embed.regex.test(item.video_url)
  );
  const { groups } = item.video_url.match(regex);
  const fill = source =>
    source.replace(/%\{(\w+)\}/g, (_, name) => groups[name]);

  return {
    ...item,
    isVideoFile: key === 'mp4',
    videoSrc: fill(template.match(/src="([^"]+)"/)[1]),
    thumbnailUrl: key === 'youtube' ? fill(YOUTUBE_THUMBNAIL_URL) : null,
  };
};

const playlist = computed(() => {
  const dismissedKeys = uiSettings.value.dismissed_feature_announcements || [];

  return announcements.value
    .filter(item => !dismissedKeys.includes(dismissKey(item)))
    .map(withVideo);
});

const announcement = computed(
  () =>
    playlist.value.find(item => item.id === selectedId.value) ||
    playlist.value[0]
);

const currentIndex = computed(() => playlist.value.indexOf(announcement.value));
const isCurrent = item => item.id === announcement.value.id;

const description = computed(
  () => new MessageFormatter(announcement.value.banner_message).formattedMessage
);

const pagerDots = computed(() => {
  const start = Math.min(
    Math.max(currentIndex.value - Math.floor(MAX_PAGER_DOTS / 2), 0),
    Math.max(playlist.value.length - MAX_PAGER_DOTS, 0)
  );

  return playlist.value.slice(start, start + MAX_PAGER_DOTS);
});

const selectByOffset = offset => {
  const item = playlist.value[currentIndex.value + offset];
  if (item) selectedId.value = item.id;
};

const dismiss = () => {
  updateUISettings({
    dismissed_feature_announcements: announcements.value.map(dismissKey),
  });
};

const { arrivedState, measure } = useScroll(contentRef);
const { arrivedState: stripArrivedState, measure: measureStrip } =
  useScroll(stripRef);

const inlineStep = computed(() => (isRTL.value ? -1 : 1));

const scrollStrip = offset => {
  stripRef.value.scrollBy({
    left:
      offset *
      inlineStep.value *
      stripRef.value.clientWidth *
      STRIP_SCROLL_RATIO,
    behavior: 'smooth',
  });
};

useSwipe(dialogRef, {
  onSwipeEnd: (event, direction) => {
    if (stripRef.value?.contains(event.target)) return;
    if (direction === 'left') selectByOffset(inlineStep.value);
    if (direction === 'right') selectByOffset(-inlineStep.value);
  },
});

watch(dialogRef, dialog => dialog?.showModal());
watch([contentRef, announcement], () => nextTick(measure));
watch([stripRef, playlist], () => nextTick(measureStrip));
watch(currentIndex, async () => {
  await nextTick();
  const strip = stripRef.value;
  if (!strip) return;

  const thumbnail = strip.querySelector('[aria-current="true"]');
  const offset =
    thumbnail.getBoundingClientRect().left - strip.getBoundingClientRect().left;

  strip.scrollBy({
    left: offset - (strip.clientWidth - thumbnail.clientWidth) / 2,
    behavior: 'smooth',
  });
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <dialog
    v-if="announcement"
    ref="dialogRef"
    class="w-[calc(100vw-2rem)] max-w-[88rem] max-h-[90dvh] m-auto overflow-y-auto shadow-2xl rounded-2xl bg-n-background/60 outline outline-1 outline-n-strong/50 backdrop-blur-2xl animate-scale-in motion-reduce:animate-none backdrop:bg-n-alpha-black1 backdrop:backdrop-blur-sm backdrop:animate-fade-in lg:w-[86vw]"
    @close="dismiss"
    @click.self="dismiss"
    @keydown.left="selectByOffset(-inlineStep)"
    @keydown.right="selectByOffset(inlineStep)"
  >
    <div
      class="relative grid grid-cols-1 overflow-hidden lg:grid-cols-12 lg:min-h-[70dvh]"
    >
      <img
        v-if="announcement.thumbnailUrl"
        :key="announcement.id"
        :src="announcement.thumbnailUrl"
        alt=""
        decoding="async"
        class="absolute inset-0 object-cover scale-125 pointer-events-none size-full blur-3xl opacity-45 saturate-150 animate-fade-in dark:opacity-50 dark:saturate-150 dark:brightness-75"
      />
      <div
        class="relative flex flex-col items-center justify-center gap-4 p-4 lg:col-span-8 lg:gap-6 lg:p-14"
      >
        <div
          v-if="!announcement.thumbnailUrl"
          aria-hidden="true"
          class="absolute inset-0 bg-[repeating-linear-gradient(135deg,transparent_0,transparent_0.5rem,rgb(var(--slate-6))_0.5rem,rgb(var(--slate-6))_calc(0.5rem+1px))] [mask-image:radial-gradient(ellipse_at_center,black_35%,transparent_90%)]"
        />
        <div
          :key="announcement.id"
          class="relative w-full overflow-hidden rounded-xl shadow-xl shadow-n-slate-3/50 bg-n-alpha-2 aspect-video animate-fade-in"
        >
          <video
            v-if="announcement.isVideoFile"
            :src="announcement.videoSrc"
            controls
            preload="metadata"
            class="size-full"
          />
          <iframe
            v-else
            :src="announcement.videoSrc"
            :title="announcement.title"
            allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media"
            allowfullscreen
            class="size-full"
          />
        </div>
        <div v-if="playlist.length > 1" class="relative w-full">
          <div
            ref="stripRef"
            class="flex gap-2 overflow-x-auto no-scrollbar [mask-image:linear-gradient(to_right,transparent,black_var(--fade-start),black_calc(100%_-_var(--fade-end)),transparent)] rtl:[mask-image:linear-gradient(to_left,transparent,black_var(--fade-start),black_calc(100%_-_var(--fade-end)),transparent)]"
            :class="[
              stripArrivedState.left
                ? '[--fade-start:0rem]'
                : '[--fade-start:5rem]',
              stripArrivedState.right
                ? '[--fade-end:0rem]'
                : '[--fade-end:5rem]',
            ]"
          >
            <button
              v-for="item in playlist"
              :key="item.id"
              type="button"
              class="w-44 p-1 group shrink-0 first:ms-auto last:me-auto"
              :title="item.title"
              :aria-current="isCurrent(item)"
              @click="selectedId = item.id"
            >
              <span
                class="relative block overflow-hidden transition-opacity rounded-lg aspect-video bg-n-alpha-2 outline"
                :class="
                  isCurrent(item)
                    ? 'outline-2 outline-offset-2 outline-n-brand'
                    : 'outline-1 outline-n-container opacity-70 group-hover:opacity-100'
                "
              >
                <img
                  v-if="item.thumbnailUrl"
                  :src="item.thumbnailUrl"
                  alt=""
                  loading="lazy"
                  class="object-cover size-full"
                />
                <span
                  class="absolute inset-x-0 bottom-0 flex items-center gap-1.5 px-2 pt-6 pb-1.5 text-white text-label-small text-start bg-gradient-to-t from-n-black/80 to-transparent"
                >
                  <Icon
                    v-if="isCurrent(item)"
                    icon="i-lucide-audio-lines"
                    class="size-3.5 shrink-0"
                  />
                  <span class="truncate">{{ item.title }}</span>
                </span>
              </span>
            </button>
          </div>
          <Button
            v-if="!stripArrivedState.left"
            icon="i-lucide-chevron-left"
            color="slate"
            size="sm"
            class="absolute -translate-y-1/2 shadow-md top-1/2 start-0 !rounded-full rtl:rotate-180"
            :aria-label="t('FEATURE_ANNOUNCEMENT.PREVIOUS')"
            @click="scrollStrip(-1)"
          />
          <Button
            v-if="!stripArrivedState.right"
            icon="i-lucide-chevron-right"
            color="slate"
            size="sm"
            class="absolute -translate-y-1/2 shadow-md top-1/2 end-0 !rounded-full rtl:rotate-180"
            :aria-label="t('FEATURE_ANNOUNCEMENT.NEXT')"
            @click="scrollStrip(1)"
          />
        </div>
      </div>
      <div
        class="relative border-t bg-n-solid-1/80 border-n-strong/50 lg:col-span-4 lg:border-t-0 lg:border-s"
      >
        <div class="flex flex-col lg:absolute lg:inset-0">
          <div
            class="flex items-center justify-between px-6 pt-5 lg:px-8 lg:pt-7"
          >
            <span
              class="px-2 py-1 rounded-md text-label-small text-n-blue-11 bg-n-blue-3"
            >
              {{ t('FEATURE_ANNOUNCEMENT.BADGE') }}
            </span>
            <Button
              icon="i-lucide-x"
              variant="ghost"
              color="slate"
              size="sm"
              :aria-label="t('FEATURE_ANNOUNCEMENT.CLOSE')"
              @click="dismiss"
            />
          </div>
          <div
            ref="contentRef"
            class="flex-1 px-6 py-5 lg:px-8 lg:py-6 lg:overflow-y-auto"
            :class="{
              '[mask-image:linear-gradient(to_bottom,black_calc(100%-4rem),transparent)]':
                !arrivedState.bottom,
            }"
          >
            <div :key="announcement.id" class="animate-fade-in">
              <h1
                class="mb-3 text-2xl font-medium tracking-tight font-interDisplay text-n-slate-12 text-balance"
              >
                {{ announcement.title }}
              </h1>
              <div
                v-dompurify-html="description"
                class="text-body-para text-n-slate-11 text-pretty [&_p]:text-body-para [&_p]:mb-5 [&_p:last-child]:mb-0 [&_strong]:font-520 [&_strong]:text-n-slate-12 [&_a]:font-460 [&_a]:text-n-blue-11 hover:[&_a]:underline [&_ul]:mb-5 [&_ul]:space-y-3 [&_ul]:list-none [&_li]:relative [&_li]:text-body-para [&_li]:ps-7 [&_li]:before:content-[''] [&_li]:before:i-lucide-check [&_li]:before:absolute [&_li]:before:start-0 [&_li]:before:top-0.5 [&_li]:before:size-4 [&_li]:before:text-n-blue-11"
              />
            </div>
          </div>
          <div
            class="flex items-center justify-between gap-4 px-6 py-4 border-t border-n-strong/50 lg:px-8 lg:py-5"
          >
            <div
              v-if="playlist.length > 1"
              class="flex items-center min-w-0 -ms-2"
            >
              <Button
                icon="i-lucide-chevron-left"
                variant="ghost"
                color="slate"
                size="sm"
                class="rtl:rotate-180"
                :disabled="currentIndex === 0"
                :aria-label="t('FEATURE_ANNOUNCEMENT.PREVIOUS')"
                @click="selectByOffset(-1)"
              />
              <button
                v-for="item in pagerDots"
                :key="item.id"
                type="button"
                class="p-2 group"
                :aria-label="item.title"
                :aria-current="isCurrent(item)"
                @click="selectedId = item.id"
              >
                <span
                  class="block h-2 transition-all rounded-full"
                  :class="
                    isCurrent(item)
                      ? 'w-6 bg-n-brand'
                      : 'w-2 bg-n-slate-8 group-hover:bg-n-slate-10'
                  "
                />
              </button>
              <Button
                icon="i-lucide-chevron-right"
                variant="ghost"
                color="slate"
                size="sm"
                class="rtl:rotate-180"
                :disabled="currentIndex === playlist.length - 1"
                :aria-label="t('FEATURE_ANNOUNCEMENT.NEXT')"
                @click="selectByOffset(1)"
              />
            </div>
            <I18nT
              v-else
              keypath="FEATURE_ANNOUNCEMENT.DISMISS_HINT"
              tag="span"
              class="invisible text-label-small text-n-slate-10 lg:visible"
            >
              <template #key>
                <kbd
                  class="px-1.5 py-0.5 rounded text-label-small text-n-slate-11 bg-n-alpha-2"
                >
                  {{ t('FEATURE_ANNOUNCEMENT.ESCAPE_KEY') }}
                </kbd>
              </template>
            </I18nT>
            <Button
              :label="t('FEATURE_ANNOUNCEMENT.DISMISS')"
              class="shrink-0"
              @click="dismiss"
            />
          </div>
        </div>
      </div>
    </div>
  </dialog>
</template>
