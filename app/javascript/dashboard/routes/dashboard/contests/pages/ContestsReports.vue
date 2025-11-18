<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const store = useStore();

const contests = computed(() => store.getters['contests/getRecords']);

const allEntries = computed(() =>
  contests.value.flatMap(contest =>
    (contest.entries || []).map(entry => ({
      ...entry,
      contestTitle: contest.name,
    }))
  )
);

const summary = computed(() => ({
  contests: contests.value.length,
  entries: allEntries.value.length,
}));

const formatDateTime = value => {
  if (!value) return '—';
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: '2-digit',
    hour: 'numeric',
    minute: 'numeric',
  }).format(new Date(value));
};
</script>

<template>
  <div
    class="mx-auto flex w-full max-w-5xl flex-col gap-6 px-6 pb-10 pt-6 md:px-8"
  >
    <div
      class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between"
    >
      <div class="space-y-1">
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ $t('CONTESTS.REPORTS_HEADING') }}
        </h2>
        <p class="text-sm text-n-slate-11">
          {{ $t('CONTESTS.REPORTS_SUBHEADING') }}
        </p>
      </div>
    </div>

    <div class="grid gap-4 md:grid-cols-2">
      <div
        class="flex items-center gap-3 rounded-2xl border border-n-alpha-3 bg-white px-5 py-4 shadow-sm dark:bg-n-solid-2"
      >
        <div
          class="grid size-10 place-content-center rounded-full bg-n-blue-3 text-n-blue-10"
        >
          <Icon icon="i-lucide-trophy" class="size-5" />
        </div>
        <div>
          <p class="text-xs uppercase tracking-wide text-n-slate-10">
            {{ $t('CONTESTS.REPORTS_TOTAL_CONTESTS') }}
          </p>
          <p class="text-2xl font-semibold text-n-slate-12">
            {{ summary.contests }}
          </p>
        </div>
      </div>
      <div
        class="flex items-center gap-3 rounded-2xl border border-n-alpha-3 bg-white px-5 py-4 shadow-sm dark:bg-n-solid-2"
      >
        <div
          class="grid size-10 place-content-center rounded-full bg-n-teal-3 text-n-teal-9"
        >
          <Icon icon="i-lucide-users" class="size-5" />
        </div>
        <div>
          <p class="text-xs uppercase tracking-wide text-n-slate-10">
            {{ $t('CONTESTS.REPORTS_TOTAL_ENTRIES') }}
          </p>
          <p class="text-2xl font-semibold text-n-slate-12">
            {{ summary.entries }}
          </p>
        </div>
      </div>
    </div>

    <div
      class="overflow-hidden rounded-2xl border border-n-alpha-2 bg-white shadow-sm dark:bg-n-solid-2"
    >
      <table class="min-w-full divide-y divide-n-alpha-2 text-left text-sm">
        <thead class="bg-n-alpha-1/60 uppercase tracking-wide text-n-slate-11">
          <tr>
            <th class="px-6 py-3 font-medium">
              {{ $t('CONTESTS.REPORTS_TABLE_PARTICIPANT') }}
            </th>
            <th class="px-6 py-3 font-medium">
              {{ $t('CONTESTS.REPORTS_TABLE_CONTACT') }}
            </th>
            <th class="px-6 py-3 font-medium">
              {{ $t('CONTESTS.REPORTS_TABLE_CONTEST') }}
            </th>
            <th class="px-6 py-3 font-medium">
              {{ $t('CONTESTS.REPORTS_TABLE_SUBMITTED_AT') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-alpha-2 text-n-slate-12">
          <tr v-for="entry in allEntries" :key="entry.id">
            <td class="px-6 py-4">
              <div class="font-medium">{{ entry.name }}</div>
            </td>
            <td class="px-6 py-4">
              <div>{{ entry.email }}</div>
              <div class="text-xs text-n-slate-11">
                {{ entry.phone }}
              </div>
            </td>
            <td class="px-6 py-4">
              {{ entry.contestTitle }}
            </td>
            <td class="px-6 py-4">
              {{ formatDateTime(entry.submittedAt) }}
            </td>
          </tr>
          <tr v-if="!allEntries.length">
            <td
              class="px-6 py-5 text-center text-sm text-n-slate-11"
              colspan="4"
            >
              {{ $t('CONTESTS.REPORTS_EMPTY_STATE') }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
