<template>
  <div class="wizard-body columns content-box small-9">
    <empty-state
      :title="$t('TEAMS_SETTINGS.FINISH.TITLE')"
      :message="$t('TEAMS_SETTINGS.FINISH.MESSAGE')"
      :button-text="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
    >
      <div class="medium-12 columns text-center">
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
import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  components: {
    EmptyState,
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.website--code {
  margin: $space-normal auto;
  max-width: 70%;
}
</style>
