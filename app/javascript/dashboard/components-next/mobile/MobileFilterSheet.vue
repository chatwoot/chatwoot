<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useHaptics } from 'dashboard/composables/useHaptics';
import MobileBottomSheet from './MobileBottomSheet.vue';
import { vHapticTap } from './hapticTap';

const props = defineProps({
  status: {
    type: String,
    default: 'open',
  },
  assigneeType: {
    type: String,
    default: 'me',
  },
  sortBy: {
    type: String,
    default: 'last_activity_at_desc',
  },
  inboxId: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['apply', 'close']);
const { t } = useI18n();
const { selection } = useHaptics();

const inboxes = useMapGetter('inboxes/getInboxes');

const selectedStatus = ref(props.status);
const selectedAssignee = ref(props.assigneeType);
const selectedSort = ref(props.sortBy);
const selectedInboxId = ref(props.inboxId);

const onInboxSelect = inboxId => {
  selection();
  selectedInboxId.value = inboxId;
};

const statusOptions = [
  { key: 'open', label: 'Open' },
  { key: 'resolved', label: 'Resolved' },
  { key: 'pending', label: 'Pending' },
  { key: 'snoozed', label: 'Snoozed' },
  { key: 'all', label: 'All' },
];

const assigneeOptions = [
  { key: 'me', label: 'Mine' },
  { key: 'unassigned', label: 'Unassigned' },
  { key: 'all', label: 'All' },
];

const sortOptions = [
  { key: 'last_activity_at_desc', label: 'Latest activity' },
  { key: 'created_at_desc', label: 'Newest' },
  { key: 'created_at_asc', label: 'Oldest' },
  { key: 'priority_desc', label: 'Priority' },
  { key: 'waiting_since_asc', label: 'Longest waiting' },
];

const onApply = () => {
  emit('apply', {
    status: selectedStatus.value,
    assigneeType: selectedAssignee.value,
    sortBy: selectedSort.value,
    inboxId: selectedInboxId.value,
  });
};

const onReset = () => {
  selectedStatus.value = 'open';
  selectedAssignee.value = 'me';
  selectedSort.value = 'last_activity_at_desc';
  selectedInboxId.value = 0;
};
</script>

<template>
  <MobileBottomSheet
    :title="t('MOBILE.FILTER_SHEET.TITLE')"
    @close="emit('close')"
  >
    <!-- Status -->
    <div class="mb-4">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block"
      >
        {{ t('MOBILE.FILTER_SHEET.STATUS') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="opt in statusOptions"
          :key="opt.key"
          class="px-3 py-1.5 rounded-full text-sm font-medium border transition-colors"
          :class="
            selectedStatus === opt.key
              ? 'border-n-brand bg-n-brand/10 text-n-brand'
              : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
          "
          @click="selectedStatus = opt.key"
        >
          {{ opt.label }}
        </button>
      </div>
    </div>

    <!-- Assignee -->
    <div class="mb-4">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block"
      >
        {{ t('MOBILE.FILTER_SHEET.ASSIGNEE') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="opt in assigneeOptions"
          :key="opt.key"
          class="px-3 py-1.5 rounded-full text-sm font-medium border transition-colors"
          :class="
            selectedAssignee === opt.key
              ? 'border-n-brand bg-n-brand/10 text-n-brand'
              : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
          "
          @click="selectedAssignee = opt.key"
        >
          {{ opt.label }}
        </button>
      </div>
    </div>

    <!-- Inbox -->
    <div v-if="inboxes.length > 1" class="mb-4">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block"
      >
        {{ t('MOBILE.FILTER_SHEET.INBOX') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <button
          v-haptic-tap
          class="px-3 py-1.5 rounded-full text-sm font-medium border transition-colors"
          :class="
            selectedInboxId === 0
              ? 'border-n-brand bg-n-brand/10 text-n-brand'
              : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
          "
          @click="onInboxSelect(0)"
        >
          {{ t('MOBILE.FILTER_SHEET.INBOX_ALL') }}
        </button>
        <button
          v-for="inbox in inboxes"
          :key="inbox.id"
          v-haptic-tap
          class="px-3 py-1.5 rounded-full text-sm font-medium border transition-colors max-w-full truncate"
          :class="
            selectedInboxId === inbox.id
              ? 'border-n-brand bg-n-brand/10 text-n-brand'
              : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
          "
          @click="onInboxSelect(inbox.id)"
        >
          {{ inbox.name }}
        </button>
      </div>
    </div>

    <!-- Sort -->
    <div class="mb-6">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block"
      >
        {{ t('MOBILE.FILTER_SHEET.SORT_BY') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="opt in sortOptions"
          :key="opt.key"
          class="px-3 py-1.5 rounded-full text-sm font-medium border transition-colors"
          :class="
            selectedSort === opt.key
              ? 'border-n-brand bg-n-brand/10 text-n-brand'
              : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
          "
          @click="selectedSort = opt.key"
        >
          {{ opt.label }}
        </button>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex gap-3">
      <button
        class="flex-1 py-2.5 text-sm font-medium text-n-slate-11 rounded-lg border border-n-weak active:bg-n-alpha-1"
        @click="onReset"
      >
        {{ t('MOBILE.FILTER_SHEET.RESET') }}
      </button>
      <button
        class="flex-1 py-2.5 text-sm font-medium text-white bg-n-brand rounded-lg active:opacity-90"
        @click="onApply"
      >
        {{ t('MOBILE.FILTER_SHEET.APPLY') }}
      </button>
    </div>
  </MobileBottomSheet>
</template>
