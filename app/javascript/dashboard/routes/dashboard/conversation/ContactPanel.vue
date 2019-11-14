<template>
  <div class="medium-3 bg-white contact--panel">
    <thumbnail
      :src="contactImage"
      size="80px"
      :badge="contact.channel"
      :username="contact.name"
    />
    <h4>
      {{ contact.name }}
    </h4>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    contact() {
      const { meta: { sender = {} } = {} } = this.currentChat || {};
      return sender;
    },
    contactImage() {
      return `/uploads/avatar/contact/${this.contact.id}/profilepic.jpeg`;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact--panel {
  @include border-normal-left;
  display: flex;
  flex-direction: column;
  padding: $space-large $space-normal $space-normal;
  align-items: center;
}
</style>
