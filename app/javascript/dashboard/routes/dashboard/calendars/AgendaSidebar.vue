<script setup>
import { computed } from 'vue';
import { formatTime } from 'dashboard/helper/calendarTime';

const props = defineProps({
  groups: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['event-click']);

const daysWithEvents = computed(() =>
  props.groups
    .map(group => ({
      ...group,
      events: (group.events || []).filter(event => !event.deleted),
    }))
    .filter(group => group.events.length)
);

const deletedEvents = computed(() =>
  props.groups.flatMap(group =>
    (group.events || []).filter(event => event.deleted)
  )
);
</script>

<template>
  <aside
    class="hidden md:flex flex-col w-64 shrink-0 border-r border-n-weak overflow-auto px-3 py-4"
  >
    <h2 class="px-1 mb-3 text-sm font-medium text-n-slate-12">
      {{ $t('SIDEBAR.CALENDAR_PAGE.AGENDA') }}
    </h2>
    <p v-if="!daysWithEvents.length" class="px-1 text-sm text-n-slate-11">
      {{ $t('SIDEBAR.CALENDAR_PAGE.NO_EVENTS') }}
    </p>
    <div v-else class="flex flex-col gap-5">
      <section v-for="group in daysWithEvents" :key="group.key">
        <h3 class="px-1 mb-2 text-xs font-medium text-n-slate-11 capitalize">
          {{ group.label }}
        </h3>
        <div class="flex flex-col gap-0.5">
          <button
            v-for="event in group.events"
            :key="event.id"
            type="button"
            class="flex w-full items-start gap-2 rounded-lg px-1 py-1.5 text-left hover:bg-n-alpha-2"
            @click="emit('event-click', event)"
          >
            <span
              class="mt-1.5 size-2 shrink-0 rounded-full bg-n-blue-9"
              aria-hidden="true"
            />
            <span class="min-w-0 flex-1">
              <span class="block text-sm text-n-slate-12 truncate">
                {{ event.summary }}
              </span>
              <span class="block text-[11px] text-n-slate-11 truncate">
                {{
                  event.all_day
                    ? $t('SIDEBAR.CALENDAR_PAGE.ALL_DAY')
                    : formatTime(event.start)
                }}
                <template v-if="event.created_by?.name">
                  · {{ event.created_by.name }}
                </template>
              </span>
            </span>
          </button>
        </div>
      </section>
    </div>
    <section
      v-if="deletedEvents.length"
      class="mt-6 pt-4 border-t border-n-ruby-6"
    >
      <h3 class="px-1 mb-2 text-xs font-medium text-n-ruby-11">
        {{ $t('SIDEBAR.CALENDAR_PAGE.DELETED_SECTION') }}
      </h3>
      <div class="flex flex-col gap-0.5">
        <button
          v-for="event in deletedEvents"
          :key="event.id"
          type="button"
          class="flex w-full items-start gap-2 rounded-lg px-1 py-1.5 text-left bg-n-ruby-3/50 hover:bg-n-ruby-4"
          @click="emit('event-click', event)"
        >
          <span
            class="mt-1.5 size-2 shrink-0 rounded-full bg-n-ruby-9"
            aria-hidden="true"
          />
          <span class="min-w-0 flex-1">
            <span class="block text-[10px] font-medium text-n-ruby-11">
              {{ $t('SIDEBAR.CALENDAR_PAGE.DELETED') }}
            </span>
            <span class="block text-sm text-n-ruby-11 truncate line-through">
              {{ event.summary }}
            </span>
            <span class="block text-[11px] text-n-ruby-11/80 truncate">
              {{ formatTime(event.start) }}
              <template v-if="event.deleted_by?.name">
                · {{ event.deleted_by.name }}
              </template>
            </span>
            <span
              v-if="event.deleted_note"
              class="block text-[11px] text-n-ruby-11 truncate"
            >
              {{ event.deleted_note }}
            </span>
          </span>
        </button>
      </div>
    </section>
  </aside>
</template>
