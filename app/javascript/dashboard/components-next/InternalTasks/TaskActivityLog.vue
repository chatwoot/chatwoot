<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  events: { type: Array, default: () => [] },
  taskId: { type: [String, Number], required: true },
  conversationId: { type: [String, Number], default: null },
});

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('internalTasks/getUIFlags');
const body = ref('');

const sortedEvents = computed(() =>
  [...props.events].sort((a, b) => b.createdAt - a.createdAt)
);

const eventLabel = event => {
  const key = `INTERNAL_TASKS.ACTIVITY.EVENTS.${event.eventType.toUpperCase()}`;
  const label = t(key);
  if (label !== key) return label;

  if (
    event.eventType === 'status_changed' &&
    event.metadata?.from &&
    event.metadata?.to
  ) {
    return `${event.metadata.from} → ${event.metadata.to}`;
  }
  return event.eventType;
};

const isNote = event =>
  event.eventType === 'comment' && event.metadata?.comment;

const submitNote = async () => {
  const comment = body.value.trim();
  if (!comment) return;

  await store.dispatch('internalTasks/addTaskComment', {
    taskId: props.taskId,
    conversationId: props.conversationId,
    comment,
  });
  body.value = '';
  useAlert(t('INTERNAL_TASKS.NOTES.SUCCESS'));
};
</script>

<template>
  <div class="px-4 pb-6 flex flex-col gap-3">
    <h3 class="text-sm font-semibold text-n-slate-12">
      {{ $t('INTERNAL_TASKS.ACTIVITY.TITLE') }}
    </h3>

    <div class="flex flex-col gap-2 pb-3 border-b border-n-weak">
      <textarea
        v-model="body"
        rows="2"
        class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 resize-y min-h-[56px]"
        :placeholder="$t('INTERNAL_TASKS.NOTES.PLACEHOLDER')"
      />
      <Button
        size="sm"
        color="blue"
        class="self-end"
        :label="$t('INTERNAL_TASKS.NOTES.ADD')"
        :is-loading="uiFlags.isUpdating"
        :disabled="!body.trim()"
        @click="submitNote"
      />
    </div>

    <p v-if="!sortedEvents.length" class="text-xs text-n-slate-11">
      {{ $t('INTERNAL_TASKS.ACTIVITY.EMPTY') }}
    </p>

    <ul v-else class="flex flex-col">
      <li
        v-for="event in sortedEvents"
        :key="event.id"
        class="flex items-start gap-2.5 py-2 border-b border-n-weak last:border-b-0"
      >
        <span
          class="mt-1.5 size-2 shrink-0 rounded-full bg-n-slate-8"
          :class="{ 'bg-n-slate-9': isNote(event) }"
        />
        <div
          class="min-w-0 flex-1 flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:gap-3"
        >
          <p
            v-if="isNote(event)"
            class="min-w-0 flex-1 text-sm text-n-slate-12 whitespace-pre-wrap break-words"
          >
            {{ event.metadata.comment }}
          </p>
          <p v-else class="min-w-0 flex-1 text-sm text-n-slate-12">
            {{ eventLabel(event) }}
          </p>
          <div
            class="shrink-0 flex items-center gap-2 text-xs text-n-slate-11 sm:justify-end"
          >
            <span v-if="event.user?.name" class="truncate max-w-[8rem]">
              {{ event.user.name }}
            </span>
            <span class="whitespace-nowrap">{{
              dynamicTime(event.createdAt)
            }}</span>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
