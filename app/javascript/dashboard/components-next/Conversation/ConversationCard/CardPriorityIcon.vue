<script setup>
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';

defineProps({
  priority: {
    type: String,
    default: '',
  },
  showEmpty: {
    type: Boolean,
    default: false,
  },
});
</script>

<!-- eslint-disable vue/no-static-inline-styles -->
<template>
  <div
    :title="priority"
    class="inline-flex items-center justify-center rounded-md"
  >
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

    <!-- Empty State (No Priority) -->
    <svg
      v-if="!priority && showEmpty"
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 16 16"
      fill="none"
    >
      <mask
        id="mask0_497_35561"
        style="mask-type: alpha"
        maskUnits="userSpaceOnUse"
        x="0"
        y="0"
        width="16"
        height="16"
      >
        <rect width="16" height="16" fill="#D9D9D9" />
      </mask>
      <g mask="url(#mask0_497_35561)">
        <rect
          x="2.66667"
          y="8"
          width="2.66667"
          height="5.33333"
          rx="1.33333"
          fill="#EAEAEA"
        />
        <rect
          x="6.66667"
          y="5.33325"
          width="2.66667"
          height="8"
          rx="1.33333"
          fill="#EAEAEA"
        />
        <rect
          x="10.6667"
          y="2.66675"
          width="2.66667"
          height="10.6667"
          rx="1.33333"
          fill="#EAEAEA"
        />
      </g>
    </svg>
  </div>
</template>
