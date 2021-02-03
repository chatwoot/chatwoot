<template>
  <div class="current-user--row">
    <thumbnail
      :src="currentUser.avatar_url"
      :username="currentUserAvailableName"
    />
    <div class="current-user--data">
      <h3 class="current-user--name">
        {{ currentUserAvailableName }}
      </h3>
      <h5 v-if="currentRole" class="current-user--role">
        {{ $t(`AGENT_MGMT.AGENT_TYPES.${currentRole.toUpperCase()}`) }}
      </h5>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import Thumbnail from '../../widgets/Thumbnail';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentRole: 'getCurrentRole',
    }),
    currentUserAvailableName() {
      return this.currentUser.name;
    },
  },
};
</script>

<style scoped lang="scss">
.current-user--row {
  align-items: center;
  display: flex;
}

.current-user--data {
  display: flex;
  flex-direction: column;

  .current-user--name {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    line-height: 1;
    margin-bottom: var(--space-smaller);
    margin-left: var(--space-one);
    margin-top: var(--space-micro);
  }

  .current-user--role {
    color: var(--color-gray);
    font-size: var(--font-size-mini);
    margin-bottom: var(--zero);
    margin-left: var(--space-one);
    text-transform: capitalize;
  }
}
</style>
