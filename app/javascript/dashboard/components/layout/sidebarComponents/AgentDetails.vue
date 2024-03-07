<template>
  <woot-button
    v-tooltip.right="$t(`SIDEBAR.PROFILE_SETTINGS`)"
    variant="link"
    class="items-center flex rounded-full"
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
import Thumbnail from '../../widgets/Thumbnail.vue';

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
