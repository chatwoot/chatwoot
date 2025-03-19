<script>
import EmptyState from '../../../../components/widgets/EmptyState.vue';

export default {
  components: {
    EmptyState,
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <EmptyState
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
    </EmptyState>
  </div>
</template>
