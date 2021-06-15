<template>
  <div class="inbox-item">
    <img src="~dashboard/assets/images/no_page_image.png" alt="No Page Image" />
    <div class="item--details columns">
      <h4 class="item--name">
        {{ inbox.label }}
      </h4>
      <p class="item--sub">
        Facebook
      </p>
    </div>
    <!-- <span class="ion-chevron-right arrow"></span> -->
  </div>
</template>
<script>
/* eslint no-console: 0 */
// import WootSwitch from '../ui/Switch';

export default {
  props: ['inbox'],
  created() {},
};
</script>
