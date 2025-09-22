<script setup>
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';

defineProps({
  priority: {
    type: String,
    default: '',
  },
});
</script>

<!-- eslint-disable vue/no-static-inline-styles -->
<template>
  <div class="inline-flex items-center justify-center rounded-md">
    <!-- Low Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.LOW"
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <mask
        id="mask0_2030_12879"
        style="mask-type: alpha"
        maskUnits="userSpaceOnUse"
        x="0"
        y="0"
        width="20"
        height="20"
      >
        <rect width="20" height="20" fill="#D9D9D9" />
      </mask>
      <g mask="url(#mask0_2030_12879)">
        <rect
          x="3.33301"
          y="10"
          width="3.33333"
          height="6.66667"
          rx="1.66667"
          class="fill-n-amber-9"
        />
        <rect
          x="8.33301"
          y="6.6665"
          width="3.33333"
          height="10"
          rx="1.66667"
          class="fill-n-slate-6"
        />
        <rect
          x="13.333"
          y="3.3335"
          width="3.33333"
          height="13.3333"
          rx="1.66667"
          class="fill-n-slate-6"
        />
      </g>
    </svg>

    <!-- Medium Priority  -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.MEDIUM"
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <mask
        id="mask0_2030_12879"
        style="mask-type: alpha"
        maskUnits="userSpaceOnUse"
        x="0"
        y="0"
        width="20"
        height="20"
      >
        <rect width="20" height="20" fill="#D9D9D9" />
      </mask>
      <g mask="url(#mask0_2030_12879)">
        <rect
          x="3.33301"
          y="10"
          width="3.33333"
          height="6.66667"
          rx="1.66667"
          class="fill-n-amber-9"
        />
        <rect
          x="8.33301"
          y="6.6665"
          width="3.33333"
          height="10"
          rx="1.66667"
          class="fill-n-amber-9"
        />
        <rect
          x="13.333"
          y="3.3335"
          width="3.33333"
          height="13.3333"
          rx="1.66667"
          class="fill-n-slate-6"
        />
      </g>
    </svg>

    <!-- High Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.HIGH"
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <mask
        id="mask0_2030_12879"
        style="mask-type: alpha"
        maskUnits="userSpaceOnUse"
        x="0"
        y="0"
        width="20"
        height="20"
      >
        <rect width="20" height="20" fill="#D9D9D9" />
      </mask>
      <g mask="url(#mask0_2030_12879)">
        <rect
          x="3.33301"
          y="10"
          width="3.33333"
          height="6.66667"
          rx="1.66667"
          class="fill-n-amber-9"
        />
        <rect
          x="8.33301"
          y="6.6665"
          width="3.33333"
          height="10"
          rx="1.66667"
          class="fill-n-amber-9"
        />
        <rect
          x="13.333"
          y="3.3335"
          width="3.33333"
          height="13.3333"
          rx="1.66667"
          class="fill-n-amber-9"
        />
      </g>
    </svg>

    <!-- Urgent Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.URGENT"
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <mask
        id="mask0_2030_12879"
        style="mask-type: alpha"
        maskUnits="userSpaceOnUse"
        x="0"
        y="0"
        width="20"
        height="20"
      >
        <rect width="20" height="20" fill="#D9D9D9" />
      </mask>
      <g mask="url(#mask0_2030_12879)">
        <rect
          x="3.33301"
          y="10"
          width="3.33333"
          height="6.66667"
          rx="1.66667"
          class="fill-n-ruby-9"
        />
        <rect
          x="8.33301"
          y="6.6665"
          width="3.33333"
          height="10"
          rx="1.66667"
          class="fill-n-ruby-9"
        />
        <rect
          x="13.333"
          y="3.3335"
          width="3.33333"
          height="13.3333"
          rx="1.66667"
          class="fill-n-ruby-9"
        />
      </g>
    </svg>
  </div>
</template>
