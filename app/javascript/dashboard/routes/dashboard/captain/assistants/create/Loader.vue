<script setup>
import { ref, computed, watch } from 'vue';
import { useRafFn, useElementBounding, useMouse } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsPageLayout from 'dashboard/components-next/captain/SettingsPageLayout.vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const { t } = useI18n();

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isCreating = computed(() => uiFlags.value.creatingItem);

const breadcrumbItems = computed(() => [
  {
    label: t('CAPTAIN.ASSISTANTS.SETTINGS.BREADCRUMB.ASSISTANT'),
    routeName: 'captain_assistants_index',
  },
  {
    label: t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.TITLE'),
    routeName: 'captain_assistants_create',
  },
]);

const pageContainer = ref(null);
const svgRef = ref(null);
const eye1Group = ref(null);
const eye2Group = ref(null);

const { x: mouseX, y: mouseY } = useMouse();
const { left, top, width, height } = useElementBounding(svgRef);
const {
  left: containerLeft,
  top: containerTop,
  right: containerRight,
  bottom: containerBottom,
} = useElementBounding(pageContainer);

const pos = ref({
  eye1: { x: 0, y: 0 },
  eye2: { x: 0, y: 0 },
});

const BASE_MAX_TRAVEL = 6;

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, c) => a + (b - a) * c;

const setTransform = (el, x, y) => {
  if (el)
    el.setAttribute('transform', `translate(${x.toFixed(3)}, ${y.toFixed(3)})`);
};

const isMouseInContainer = computed(() => {
  return (
    mouseX.value >= containerLeft.value &&
    mouseX.value <= containerRight.value &&
    mouseY.value >= containerTop.value &&
    mouseY.value <= containerBottom.value
  );
});

useRafFn(() => {
  if (!svgRef.value || !width.value || !height.value) return;

  const cx = left.value + width.value / 2;
  const cy = top.value + height.value / 2;

  let dx = 0;
  let dy = 0;

  if (isMouseInContainer.value) {
    dx = mouseX.value - cx;
    dy = mouseY.value - cy;
  }

  const len = Math.hypot(dx, dy) || 1;

  const scale = Math.min(width.value, height.value) / 100;
  const maxTravel = BASE_MAX_TRAVEL * Math.max(1, scale);

  const travelX = (dx / len) * clamp(len * 0.08, 0, maxTravel);
  const travelY = (dy / len) * clamp(len * 0.06, 0, maxTravel * 0.8);

  const targetEye1X = travelX * 0.9;
  const targetEye1Y = travelY * 0.9;
  const targetEye2X = travelX * 1.1;
  const targetEye2Y = travelY * 1.1;

  pos.value.eye1.x = lerp(pos.value.eye1.x, targetEye1X, 0.18);
  pos.value.eye1.y = lerp(pos.value.eye1.y, targetEye1Y, 0.18);
  pos.value.eye2.x = lerp(pos.value.eye2.x, targetEye2X, 0.18);
  pos.value.eye2.y = lerp(pos.value.eye2.y, targetEye2Y, 0.18);

  setTransform(eye1Group.value, pos.value.eye1.x, pos.value.eye1.y);
  setTransform(eye2Group.value, pos.value.eye2.x, pos.value.eye2.y);
});

watch(isCreating, (newVal, oldVal) => {
  if (oldVal && !newVal) {
    setTimeout(() => {
      router.push({ name: 'captain_assistants_create_settings' });
    }, 5000);
  }
});
</script>

<template>
  <SettingsPageLayout ref="pageContainer" :breadcrumb-items="breadcrumbItems">
    <template #body>
      <div class="w-full h-full flex flex-col items-center justify-center">
        <div
          class="relative w-full max-w-[450px] aspect-square flex items-center justify-center"
        >
          <div
            class="absolute inset-0 flex items-center justify-center pointer-events-none"
          >
            <div
              v-for="(delay, i) in [0, 200, 400]"
              :key="i"
              class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 scale-1 aspect-square rounded-full border border-n-slate-3 animate-ripple"
              :class="`w-[${60 + i * 20}%]`"
              :style="{ animationDelay: `${delay}ms` }"
              aria-hidden="true"
            />
          </div>

          <div class="relative flex items-center justify-center w-full h-full">
            <svg
              ref="svgRef"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 59 48"
              width="59"
              height="48"
              class="block touch-none"
            >
              <path
                fill-rule="evenodd"
                clip-rule="evenodd"
                d="M44.1624 5.66847C33.8484 4.21327 25.4409 4.15585 14.8951 5.66206C12.2294 6.0428 10.4657 6.30009 9.12091 6.69312C7.87394 7.05755 7.16477 7.49209 6.57821 8.14764C5.36358 9.50511 5.20348 11.0404 5.03792 16.395C4.87521 21.6574 5.19749 26.3737 5.80791 31.6803C6.13318 34.508 6.35702 36.4164 6.71439 37.8673C7.05338 39.2435 7.46339 39.9835 8.03322 40.55C8.6076 41.121 9.34372 41.5236 10.6947 41.8504C12.1237 42.1961 13.9988 42.4051 16.7854 42.7091C25.7979 43.6924 32.5443 43.6875 41.5903 42.7143C44.4107 42.4109 46.3164 42.2017 47.7668 41.8584C49.1447 41.5322 49.8856 41.1324 50.452 40.5777C51.0065 40.0347 51.4303 39.2856 51.7977 37.8408C52.1812 36.3334 52.4421 34.3388 52.8196 31.4086C53.4932 26.1807 53.9782 21.5894 53.9971 16.5598C54.0172 11.1822 53.9072 9.65207 52.6789 8.23286C52.0856 7.5474 51.3643 7.09668 50.0889 6.72132C48.7116 6.31599 46.9002 6.05475 44.1624 5.66847ZM14.2512 1.15321C25.2368 -0.415832 34.0757 -0.354388 44.7987 1.15853L44.9556 1.18066C47.4945 1.53877 49.6395 1.84131 51.3748 2.35201C53.2476 2.90317 54.8137 3.73986 56.1227 5.25214C58.5918 8.10489 58.5757 11.4896 58.5543 15.9864C58.5533 16.1811 58.5524 16.3779 58.5517 16.5768C58.5317 21.8948 58.0172 26.7103 57.3369 31.9906L57.3189 32.1303C56.9639 34.8859 56.6714 37.1566 56.2118 38.9636C55.7285 40.8637 55.0061 42.4928 53.6387 43.8319C52.2832 45.1592 50.6815 45.849 48.8158 46.2906C47.054 46.7076 44.8618 46.9434 42.2194 47.2275L42.0775 47.2428C32.7099 48.2506 25.6345 48.2562 16.2914 47.2369L16.1473 47.2211C13.5418 46.9369 11.3724 46.7003 9.62384 46.2773C7.76507 45.8277 6.17397 45.124 4.82206 43.78C3.4656 42.4314 2.75316 40.8289 2.29197 38.9566C1.85699 37.1907 1.60412 34.9919 1.29963 32.3441L1.28314 32.2008C0.657117 26.7585 0.313761 21.8082 0.485489 16.2542C0.49172 16.0527 0.49768 15.8534 0.503576 15.6563C0.637065 11.1931 0.737198 7.84512 3.18398 5.11059C4.48215 3.65975 6.01657 2.85525 7.84323 2.32139C9.53736 1.82627 11.6262 1.52801 14.0987 1.17499C14.1493 1.16775 14.2002 1.16049 14.2512 1.15321Z"
                class="fill-n-slate-10"
              />
              <g ref="eye1Group">
                <path
                  d="M13.7949 16.0392C13.7949 14.5096 15.035 13.2695 16.5646 13.2695C18.0943 13.2695 19.3343 14.5096 19.3343 16.0392V22.4403C19.3343 23.97 18.0943 25.21 16.5646 25.21C15.035 25.21 13.7949 23.97 13.7949 22.4403V16.0392Z"
                  class="fill-n-slate-10"
                />
              </g>
              <g ref="eye2Group">
                <path
                  d="M22.6572 16.0392C22.6572 14.5096 23.8973 13.2695 25.4269 13.2695C26.9566 13.2695 28.1966 14.5096 28.1966 16.0392V22.4403C28.1966 23.97 26.9566 25.21 25.4269 25.21C23.8973 25.21 22.6572 23.97 22.6572 22.4403V16.0392Z"
                  class="fill-n-slate-10"
                />
              </g>
            </svg>
          </div>
        </div>
        <div class="h-32 flex items-center justify-center">
          <h5 class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.ONBOARDING.CREATING') }}
          </h5>
        </div>
      </div>
    </template>
  </SettingsPageLayout>
</template>

<style scoped>
@keyframes rippleScale {
  0% {
    transform: translate(-50%, -50%) scale(0);
    opacity: 1;
  }
  50% {
    transform: translate(-50%, -50%) scale(0.9);
    opacity: 0.9;
  }
  100% {
    transform: translate(-50%, -50%) scale(1.2);
    opacity: 0;
  }
}

.animate-ripple {
  animation: rippleScale 2200ms cubic-bezier(0.2, 0.8, 0.2, 1) infinite;
}
</style>
