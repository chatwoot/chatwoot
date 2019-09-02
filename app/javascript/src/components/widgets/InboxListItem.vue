<template>
  <div class="inbox-item">
    <img src="~assets/images/no_page_image.png" alt="No Page Image" />
    <div class="item--details columns">
      <h4 class="item--name">
        {{ inbox.label }}
      </h4>
      <p class="item--sub">
        <span v-if="inbox.channelType === 'EmailInbox'">Email</span>
        <span v-if="inbox.channelType === 'FacebookPage'">Facebook</span>
      </p>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  created() {},
};
</script>
