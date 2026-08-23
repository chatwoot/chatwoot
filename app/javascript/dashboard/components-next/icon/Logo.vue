<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <!-- [chatpaw] fallback mark: blob mascot with paw badge -->
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <svg
    v-else
    v-once
    v-bind="attrs"
    width="16"
    height="16"
    viewBox="0 0 120 120"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <defs>
      <linearGradient id="cp-fallback-body" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#1fe0b5" />
        <stop offset="1" stop-color="#1ba5ff" />
      </linearGradient>
    </defs>
    <path
      fill="url(#cp-fallback-body)"
      d="M60 12 C90 12 106 38 106 64 C106 92 88 106 60 106 C32 106 14 92 14 64 C14 38 30 12 60 12 Z"
    />
    <ellipse cx="44" cy="52" rx="7.5" ry="9" fill="#06251f" />
    <ellipse cx="76" cy="52" rx="7.5" ry="9" fill="#06251f" />
    <circle cx="46.5" cy="48.5" r="2.4" fill="#fff" />
    <circle cx="78.5" cy="48.5" r="2.4" fill="#fff" />
    <path
      d="M46 72 Q60 82 74 72"
      stroke="#06251f"
      stroke-width="4.5"
      stroke-linecap="round"
      fill="none"
    />
    <g transform="translate(60 92)">
      <ellipse cx="0" cy="1.5" rx="6.5" ry="5" fill="#ffc857" />
      <circle cx="-6" cy="-4.5" r="2.3" fill="#ffc857" />
      <circle cx="-2.2" cy="-7" r="2.3" fill="#ffc857" />
      <circle cx="2.2" cy="-7" r="2.3" fill="#ffc857" />
      <circle cx="6" cy="-4.5" r="2.3" fill="#ffc857" />
    </g>
    <line
      x1="60"
      y1="12"
      x2="60"
      y2="4"
      stroke="#1fe0b5"
      stroke-width="3"
      stroke-linecap="round"
    />
    <circle cx="60" cy="3" r="3" fill="#ffc857" />
  </svg>
</template>
