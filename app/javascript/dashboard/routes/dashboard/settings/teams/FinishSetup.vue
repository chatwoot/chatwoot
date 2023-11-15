<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <empty-state
      :title="$t('TEAMS_SETTINGS.FINISH.TITLE')"
      :message="$t('TEAMS_SETTINGS.FINISH.MESSAGE')"
      :button-text="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <router-link
          class="button success nice"
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
<style lang="scss" scoped>
.website--code {
  @apply my-4 mx-auto max-w-[70%];
}
</style>
