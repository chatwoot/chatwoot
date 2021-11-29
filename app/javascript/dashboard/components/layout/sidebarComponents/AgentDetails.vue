<template>
  <woot-button
    v-tooltip.right="$t(`SIDEBAR.PROFILE_SETTINGS`)"
    variant="link"
    class="current-user"
    @click="handleClick"
  >
    <thumbnail
      :src="currentUser.avatar_url"
      :username="currentUser.name"
      :status="statusOfAgent"
      should-show-status-always
      size="32px"
    />
  </woot-button>
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
      currentUserAvailability: 'getCurrentUserAvailability',
    }),
    statusOfAgent() {
      return this.currentUserAvailability || 'offline';
    },
  },
  methods: {
    handleClick() {
      this.$emit('toggle-menu');
    },
  },
};
</script>

<style scoped lang="scss">
.current-user {
  align-items: center;
  display: flex;
  border-radius: 50%;
  border: 2px solid var(--white);
}
</style>
