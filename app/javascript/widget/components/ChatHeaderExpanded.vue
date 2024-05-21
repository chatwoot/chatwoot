<template>
  <header
    class="header-expanded pb-4 relative box-border w-full bg-transparent"
  >
    <div class="" style="
      background-image: url('https://marketing-homepage-images.s3.eu-west-2.amazonaws.com/vip_popup_brand_background-min.jpg');
      background-size: cover;
      background-position: center;"
    >
      <div class="" style="
        background-color: rgba(0, 0, 0, 0.6);
        padding: 1.25rem 1.25rem;"
      >
        <div
          class="flex items-start justify-between"
        >
          <img
            v-if="avatarUrl"
            class="h-12 rounded-full"
            :src="avatarUrl"
            :class="[avatarUrl ? 'justify-between' : 'justify-end']"
            alt="Avatar"
          />
          
          <!-- <img
            src="https://vinterior-chatwoot-b076ce14c212.herokuapp.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBFQT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--cbf9b5800b28ac29999ff8dc2b03b49528d760ca/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJYW5CbkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--b6a5c7f9cafa1b2ff26f5ff491e4c6222c4a9358/vinterior_v.jpg"
            class="h-12 rounded-full"
            alt="Avatar"
          /> -->

          <header-actions
            :show-popout-button="showPopoutButton"
            :show-end-conversation-button="false"
          />
        </div>

        <p class="" style="
          font-family: 'P22 Mackinac Pro Book', 'Times', 'Georgia', serif;
          color: white;
          font-size: 28px;
          margin-top: 20px;
          padding-right: 70px;"
        >Your personal shopping assistant</p>
      </div>
    </div>

    <p class="text-base leading-normal text-slate-700" style="
      padding-left: 1.25rem;
      padding-right: 1.25rem;
      padding-top: 1.25rem;
      font-size: 14px;
      line-height: 29px;"
    >
      Hello! Welcome to our exclusive shopping concierge service; a dedicated support team, available Monday through Friday from 9am to 6pm. Enjoy our best-in-class personalised shopping experience, including:
      <ul style="
        list-style: disc;
        padding-left: 1.6rem;
        padding-right: 1.25rem;"
      >
        <li>Bespoke sourcing support tailored to your needs Assistance with negotiating deals with sellers </li>
        <li>Guidance and support with your purchase & delivery arrangements</li>
      </ul>
    </p>
  </header>
</template>

<script>
import HeaderActions from './HeaderActions.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
  mixins: [darkModeMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    introHeading: {
      type: String,
      default: '',
    },
    introBody: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
