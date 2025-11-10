<script setup>
defineProps({
  summary: {
    type: Object,
    default: () => ({}),
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    <!-- Total Campaigns -->
    <div
      class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
    >
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-slate-600 dark:text-slate-400">
            {{ $t('META_CAMPAIGNS.SUMMARY.TOTAL_CAMPAIGNS') }}
          </p>
          <p
            v-if="!isLoading"
            class="mt-2 text-3xl font-semibold text-slate-900 dark:text-slate-100"
          >
            {{ summary.total_campaigns || 0 }}
          </p>
          <div
            v-else
            class="mt-2 h-8 w-16 animate-pulse rounded bg-slate-200 dark:bg-slate-700"
          />
        </div>
        <div
          class="flex h-12 w-12 items-center justify-center rounded-lg bg-blue-100 dark:bg-blue-900/30"
        />
      </div>
    </div>

    <!-- Total Interactions -->
    <div
      class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
    >
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-slate-600 dark:text-slate-400">
            {{ $t('META_CAMPAIGNS.SUMMARY.TOTAL_INTERACTIONS') }}
          </p>
          <p
            v-if="!isLoading"
            class="mt-2 text-3xl font-semibold text-slate-900 dark:text-slate-100"
          >
            {{ summary.total_interactions || 0 }}
          </p>
          <div
            v-else
            class="mt-2 h-8 w-16 animate-pulse rounded bg-slate-200 dark:bg-slate-700"
          />
        </div>
        <div
          class="flex h-12 w-12 items-center justify-center rounded-lg bg-green-100 dark:bg-green-900/30"
        />
      </div>
    </div>

    <!-- Unique Conversations -->
    <div
      class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
    >
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-slate-600 dark:text-slate-400">
            {{ $t('META_CAMPAIGNS.SUMMARY.UNIQUE_CONVERSATIONS') }}
          </p>
          <p
            v-if="!isLoading"
            class="mt-2 text-3xl font-semibold text-slate-900 dark:text-slate-100"
          >
            {{ summary.unique_conversations || 0 }}
          </p>
          <div
            v-else
            class="mt-2 h-8 w-16 animate-pulse rounded bg-slate-200 dark:bg-slate-700"
          />
        </div>
        <div
          class="flex h-12 w-12 items-center justify-center rounded-lg bg-purple-100 dark:bg-purple-900/30"
        />
      </div>
    </div>

    <!-- Conversion Rate -->
    <div
      class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
    >
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-slate-600 dark:text-slate-400">
            {{ $t('META_CAMPAIGNS.SUMMARY.CONVERSION_RATE') }}
          </p>
          <p
            v-if="!isLoading"
            class="mt-2 text-3xl font-semibold text-slate-900 dark:text-slate-100"
          >
            {{
              summary.total_interactions
                ? Math.round(
                    (summary.unique_conversations /
                      summary.total_interactions) *
                      100
                  )
                : 0
            }}{{ $t('META_CAMPAIGNS.SUMMARY.PERCENTAGE_SYMBOL') }}
          </p>
          <div
            v-else
            class="mt-2 h-8 w-16 animate-pulse rounded bg-slate-200 dark:bg-slate-700"
          />
        </div>
        <div
          class="flex h-12 w-12 items-center justify-center rounded-lg bg-yellow-100 dark:bg-yellow-900/30"
        />
      </div>
    </div>
  </div>
</template>
