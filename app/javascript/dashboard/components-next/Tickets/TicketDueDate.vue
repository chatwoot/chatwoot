<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';

const props = defineProps({
  // ISO8601 string as returned by the ticket payload.
  dueAt: {
    type: String,
    default: null,
  },
  // A case that is already done or closed cannot run late any more.
  isSettled: {
    type: Boolean,
    default: false,
  },
});

const dueDate = computed(() => (props.dueAt ? new Date(props.dueAt) : null));

const formattedDueAt = computed(() =>
  dueDate.value ? format(dueDate.value, 'MMM d, yyyy') : ''
);

const isOverdue = computed(
  () => !props.isSettled && !!dueDate.value && dueDate.value < new Date()
);
</script>

<template>
  <span
    v-if="formattedDueAt"
    class="tabular-nums"
    :class="isOverdue ? 'text-n-ruby-11' : 'text-n-slate-11'"
  >
    {{ formattedDueAt }}
  </span>
</template>
