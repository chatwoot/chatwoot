<script>
import { mapGetters } from 'vuex';
import Thumbnail from '../../widgets/Thumbnail.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Thumbnail,
    NextButton,
  },
  emits: ['toggleMenu'],
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
      this.$emit('toggleMenu');
    },
  },
};
</script>

<template>
  <NextButton
    v-tooltip.right="$t(`SIDEBAR.PROFILE_SETTINGS`)"
    link
    class="rounded-full"
    @click="handleClick"
  >
    <Thumbnail
      :src="currentUser.avatar_url"
      :username="currentUser.name"
      :status="statusOfAgent"
      should-show-status-always
      size="32px"
      class="flex-shrink-0"
    />
  </NextButton>
</template>
