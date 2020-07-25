<template>
  <div class="contact--profile">
    <div class="contact--info">
      <thumbnail
        :src="contact.thumbnail"
        size="56px"
        :badge="channelType"
        :username="contact.name"
        :status="contact.availability_status"
      />

      <div class="contact--details">
        <div class="contact--name">
          {{ contact.name }}
        </div>
        <div v-if="additionalAttibutes.description" class="contact--bio">
          {{ additionalAttibutes.description }}
        </div>
        <social-icons :social-profiles="socialProfiles" />
        <div class="contact--metadata">
          <contact-info-row
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="ion-email"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
          />
          <contact-info-row
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="ion-ios-telephone"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
          />
          <contact-info-row
            :value="additionalAttibutes.location"
            icon="ion-map"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <contact-info-row
            :value="additionalAttibutes.company"
            icon="ion-briefcase"
            :title="$t('CONTACT_PANEL.COMPANY')"
          />
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import ContactInfoRow from './ContactInfoRow';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons';

export default {
  components: {
    ContactInfoRow,
    Thumbnail,
    SocialIcons,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    contactData: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    additionalAttibutes() {
      return this.contact.additional_attributes || {};
    },
    socialProfiles() {
      const {
        profiles = { twitter: '', github: '', linkedin: '', facebook: '' },
        screen_name: twitterScreenName,
      } = this.additionalAttibutes;

      return { ...profiles, twitter: twitterScreenName };
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';
.contact--profile {
  align-items: flex-start;
  padding: $space-normal;

  .user-thumbnail-box {
    margin-right: $space-normal;
  }
}

.contact--details {
  margin-top: $space-small;

  p {
    margin-bottom: 0;
  }
}

.contact--info {
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  text-align: left;
}

.contact--name {
  @include text-ellipsis;
  text-transform: capitalize;

  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--bio {
  margin: $space-small 0 0;
}

.contact--metadata {
  margin-top: $space-small;
}

.social--icons {
  i {
    font-size: $font-weight-normal;
  }
}
</style>
