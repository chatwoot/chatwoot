<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <empty-state
      :title="$t('TEAMS_SETTINGS.FINISH.TITLE')"
      :message="$t('TEAMS_SETTINGS.FINISH.MESSAGE')"
      :button-text="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <router-link
          class="button success nice rounded"
          :to="{
            name: 'settings_teams_list',
          }"
        >
          {{ $t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT') }}
        </router-link>
      </div>
    </empty-state>
  </div>
</template>

<script>
import EmptyState from '../../../../components/widgets/EmptyState.vue';

export default {
  components: {
    EmptyState,
  },
};
</script>
