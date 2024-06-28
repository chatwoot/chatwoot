<script>
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';
export default {
  props: {
    priority: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      CONVERSATION_PRIORITY,
    };
  },
};
</script>

<template>
  <div class="inline-flex items-center justify-center rounded-md">
    <!-- High Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.HIGH"
      class="h-4 w-4"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect x="4" y="12" width="4" height="8" rx="1" fill="#FFC291" />
      <rect x="10" y="8" width="4" height="12" rx="1" fill="#FFC291" />
      <rect x="16" y="4" width="4" height="16" rx="1" fill="#FFC291" />
    </svg>

    <!-- Low Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.LOW"
      class="h-4 w-4"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect x="4" y="12" width="4" height="8" rx="1" fill="#FFC291" />
      <rect x="10" y="8" width="4" height="12" rx="1" fill="#DDDDDD" />
      <rect x="16" y="4" width="4" height="16" rx="1" fill="#DDDDDD" />
    </svg>

    <!-- Medium Priority  -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.MEDIUM"
      class="h-4 w-4"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect x="4" y="12" width="4" height="8" rx="1" fill="#FFC291" />
      <rect x="10" y="8" width="4" height="12" rx="1" fill="#FFC291" />
      <rect x="16" y="4" width="4" height="16" rx="1" fill="#DDDDDD" />
    </svg>

    <!-- Urgent Priority -->
    <svg
      v-if="priority === CONVERSATION_PRIORITY.URGENT"
      class="h-4 w-4"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect x="4" y="12" width="4" height="8" rx="1" fill="#E5484D" />
      <rect x="10" y="8" width="4" height="12" rx="1" fill="#E5484D" />
      <rect x="16" y="4" width="4" height="16" rx="1" fill="#E5484D" />
    </svg>
  </div>
</template>
