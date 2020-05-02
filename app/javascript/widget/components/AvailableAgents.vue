<template>
  <div class="available-agents">
    <div class="toast-bg">
      <div class="avatars-wrap">
        <GroupedAvatars :users="users" />
      </div>
      <div class="title">
        {{ title }}
      </div>
    </div>
  </div>
</template>

<script>
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';
import { getAvailableAgentsText } from 'widget/helpers/utils';

export default {
  name: 'AvailableAgents',
  components: { GroupedAvatars },
  props: {
    agents: {
      type: Array,
      default: () => [],
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    users() {
      return this.agents.map(agent => ({
        id: agent.id,
        avatar: agent.avatar_url,
        name: agent.name,
      }));
    },
    title() {
      return getAvailableAgentsText(this.agents);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.available-agents {
  display: flex;
  position: relative;
  justify-content: center;
  margin: $space-normal $space-medium;
  box-sizing: border-box;

  .toast-bg {
    border-radius: $space-large;
    background: $color-body;
    @include shadow-medium;
  }

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    color: $color-white;
    padding: $space-small $space-normal $space-small $space-small;
    line-height: 1.4;
    display: inline-block;
    vertical-align: middle;
  }

  .avatars-wrap {
    display: inline-block;
    vertical-align: middle;
    margin-left: $space-small;
  }
}
</style>
