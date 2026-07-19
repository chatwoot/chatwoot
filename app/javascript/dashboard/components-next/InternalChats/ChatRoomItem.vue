<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';

const props = defineProps({
  room: { type: Object, required: true },
  isActive: { type: Boolean, default: false },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const teamName = computed(
  () => props.room.team?.name || t('INTERNAL_CHATS.UNKNOWN_TEAM')
);

const preview = computed(
  () => props.room.last_message_preview || t('INTERNAL_CHATS.NO_MESSAGES')
);

const lastActivityAt = computed(() => props.room.last_activity_at || 0);
const createdAt = computed(
  () => props.room.created_at || lastActivityAt.value || 0
);

const onClick = () => emit('select', props.room.id);
const onKeydown = event => {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();
    onClick();
  }
};
</script>

<template>
  <div
    role="option"
    :aria-selected="isActive"
    :data-room-id="room.id"
    tabindex="0"
    class="group relative flex max-w-full flex-shrink-0 flex-grow-0 cursor-pointer items-start border-b border-n-slate-3 px-3 py-0 before:absolute before:inset-x-0 before:-top-px before:h-px before:bg-n-surface-1 before:content-[none] before:pointer-events-none hover:z-[1] hover:border-n-surface-1 hover:bg-n-alpha-1 hover:before:content-[''] focus:outline-none focus-visible:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-brand/40 dark:hover:bg-n-alpha-3"
    :class="{
      'active animate-card-select bg-n-background !border-n-surface-1':
        isActive,
    }"
    @click="onClick"
    @keydown="onKeydown"
  >
    <Avatar
      :name="teamName"
      :src="room.team?.thumbnail || ''"
      :size="32"
      rounded-full
      class="mt-4 shrink-0"
    />
    <div class="min-w-0 flex-1 px-0 py-3">
      <div class="mx-2 flex items-center justify-between gap-2">
        <h4
          class="min-w-0 flex-1 truncate text-sm font-medium leading-tight text-n-slate-12"
        >
          {{ teamName }}
        </h4>
        <span
          v-if="lastActivityAt"
          class="shrink-0 text-sm tabular-nums text-n-slate-10"
        >
          <TimeAgo
            :last-activity-timestamp="lastActivityAt"
            :created-at-timestamp="createdAt"
          />
        </span>
      </div>
      <p class="mx-2 mt-0.5 truncate text-sm leading-6 text-n-slate-11">
        {{ preview }}
      </p>
    </div>
  </div>
</template>
