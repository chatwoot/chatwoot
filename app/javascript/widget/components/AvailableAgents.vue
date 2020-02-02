<template>
  <header class="avaiable-agents">
    <div class="avatars-wrap">
      <GroupedAvatars :agents="agents" />
    </div>
    <div class="title">
      Pulisic and 2 others are online
      <span class="online"></span>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';

export default {
  name: 'AvailableAgents',
  components: { GroupedAvatars },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
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
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.avaiable-agents {
  display: flex;
  position: relative;
  justify-content: center;
  margin: $space-normal $space-medium;
  box-sizing: border-box;
  text-align: center;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    color: $color-white;
    padding: $space-one $space-normal $space-one $space-large;
    margin-top: $space-small;
    line-height: 1.4;
    border-radius: $space-large;
    background: $color-body;
    @include shadow-medium;
  }

  .avatars-wrap {
    width: 80px;
    position: absolute;
    left: 0rem;
    top: 1.4rem;
  }

  .online {
    width: $space-one;
    height: $space-one;
    border-radius: $space-one;
    background: #13ce66;
    display: inline-block;
    @include light-shadow;
    margin-left: $space-smaller;
  }
}
</style>
