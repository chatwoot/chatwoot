<script setup>
/**
 * Decorative artwork for the onboarding feature cards.
 *
 * Drawn inline rather than shipped as image files so the strokes and fills can
 * reference the `n-*` design tokens — those are CSS variables that flip with
 * the theme, which a raster asset cannot do.
 */
defineProps({
  name: {
    type: String,
    required: true,
    validator: value =>
      ['omnichannel', 'teams', 'cannedResponses', 'labels'].includes(value),
  },
});
</script>

<template>
  <svg
    viewBox="0 0 200 120"
    fill="none"
    aria-hidden="true"
    focusable="false"
    class="w-full max-w-[200px] h-auto"
    stroke-linecap="round"
    stroke-linejoin="round"
  >
    <!-- Separate channels folding into a single list -->
    <g v-if="name === 'omnichannel'">
      <rect
        v-for="y in [16, 49, 82]"
        :key="y"
        x="16"
        :y="y"
        width="22"
        height="22"
        rx="7"
        class="fill-n-slate-3 stroke-n-slate-7"
        stroke-width="2"
      />
      <path
        d="M38 27C58 27 58 60 78 60M38 60H78M38 93C58 93 58 60 78 60"
        class="stroke-n-slate-7"
        stroke-width="2"
      />
      <circle cx="78" cy="60" r="3.5" class="fill-n-brand" />
      <rect
        x="90"
        y="16"
        width="94"
        height="88"
        rx="12"
        class="fill-n-slate-3 stroke-n-slate-7"
        stroke-width="2"
      />
      <template v-for="y in [38, 60, 82]" :key="y">
        <circle cx="108" :cy="y" r="5" class="fill-n-slate-6" />
        <rect
          x="122"
          :y="y - 3"
          width="48"
          height="6"
          rx="3"
          class="fill-n-slate-6"
        />
      </template>
    </g>

    <!-- A row of teammates, with one seat still open -->
    <g v-else-if="name === 'teams'">
      <template v-for="cx in [52, 82, 112]" :key="cx">
        <circle
          :cx="cx"
          cy="58"
          r="17"
          class="fill-n-slate-3 stroke-n-slate-7"
          stroke-width="2"
        />
        <circle :cx="cx" cy="53" r="4.5" class="fill-n-slate-6" />
        <path :d="`M${cx - 8} 68a8 7 0 0 1 16 0z`" class="fill-n-slate-6" />
      </template>
      <circle
        cx="148"
        cy="58"
        r="17"
        class="stroke-n-brand"
        stroke-width="2"
        stroke-dasharray="4 5"
      />
      <path d="M148 51v14M141 58h14" class="stroke-n-brand" stroke-width="2" />
    </g>

    <!-- A saved reply dropped into a message by its shortcode -->
    <g v-else-if="name === 'cannedResponses'">
      <rect
        x="44"
        y="14"
        width="124"
        height="58"
        rx="12"
        class="stroke-n-slate-6"
        stroke-width="2"
      />
      <path
        d="M42 26h100a12 12 0 0 1 12 12v38a12 12 0 0 1-12 12H64l-16 14V88h-6a12 12 0 0 1-12-12V38a12 12 0 0 1 12-12z"
        class="fill-n-slate-3 stroke-n-slate-7"
        stroke-width="2"
      />
      <rect
        x="44"
        y="40"
        width="30"
        height="18"
        rx="6"
        class="fill-n-brand/10 stroke-n-brand"
        stroke-width="2"
      />
      <path d="M56 54l6-10" class="stroke-n-brand" stroke-width="2" />
      <rect x="82" y="46" width="56" height="6" rx="3" class="fill-n-slate-6" />
      <rect x="44" y="66" width="94" height="6" rx="3" class="fill-n-slate-6" />
    </g>

    <!-- Tags sorting conversations into groups -->
    <g v-else-if="name === 'labels'">
      <template
        v-for="tag in [
          { y: 14, end: 150, accent: false },
          { y: 47, end: 172, accent: true },
          { y: 80, end: 136, accent: false },
        ]"
        :key="tag.y"
      >
        <path
          :d="`M44 ${tag.y}h${tag.end - 54}a10 10 0 0 1 10 10v6a10 10 0 0 1-10 10H44L28 ${tag.y + 13}z`"
          :class="
            tag.accent
              ? 'fill-n-brand/10 stroke-n-brand'
              : 'fill-n-slate-3 stroke-n-slate-7'
          "
          stroke-width="2"
        />
        <circle
          cx="54"
          :cy="tag.y + 13"
          r="3.5"
          class="fill-n-surface-2 stroke-n-slate-7"
          stroke-width="1.5"
        />
        <rect
          x="66"
          :y="tag.y + 10"
          :width="tag.end - 78"
          height="6"
          rx="3"
          class="fill-n-slate-6"
        />
      </template>
    </g>
  </svg>
</template>
