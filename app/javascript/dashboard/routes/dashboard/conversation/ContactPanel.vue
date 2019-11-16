<template>
  <div class="medium-3 bg-white contact--panel">
    <div class="contact--profile">
      <div class="contact--info">
        <thumbnail
          :src="contactImage"
          size="56px"
          :badge="contact.channel"
          :username="contact.name"
        />
        <div class="contact--details">
          <div class="contact--name">
            {{ contact.name }}
          </div>
          <div class="contact--email">
            pranavrajs@gmail.com
          </div>
          <div class="contact--location">
            Bangalore, India
          </div>
        </div>
      </div>
      <div class="contact--bio">
        Engineer | UX | Product Design Contributing to opensource @chatwootapp
        Built @surveyjoyHQ @dataclumpHQ 🧘‍♂️🚵‍♂️ #remotework @bigbinary
      </div>
    </div>
    <div class="contact-section--header">
      <span>Conversation Details</span>
    </div>
    <div class="conversation--details">
      <div>
        <div>Conversation Started From</div>
        <div>https://chatwoot.com/</div>
      </div>
      <div>
        Web Browser and Device Chrome 75.0.3770.100 / Windows
      </div>
      <div>
        IP Address 109.49.176.155
      </div>
    </div>
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
  align-items: center;
  font-size: $font-size-small;
}

.contact--profile {
  width: 100%;
  padding: $space-normal $space-medium;
  align-items: center;
  border-bottom: 1px solid $color-border;
  .user-thumbnail-box {
    margin-right: $space-normal;
  }
}

.contact--details {
  p {
    margin-bottom: 0;
  }
}

.contact--info {
  display: flex;
  align-items: center;
}

.contact--name {
  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--email {
  text-decoration: underline;
}

.contact--bio {
  margin-top: $space-normal;
}

.contact-section--header {
  background: $color-background;
  width: 100%;
  font-size: $font-size-mini;
  padding: $space-one $space-medium;
  border-bottom: 1px solid $color-border;
  text-transform: uppercase;
  font-weight: 500;
}
</style>
