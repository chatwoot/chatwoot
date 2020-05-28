<template>
  <span class="message-text__wrap">
    <span v-html="message"></span>
    <span class="time">{{ readableTime }}</span>
    <span v-if="contactName" class="contact-name"> {{ contactName }} </span>
  </span>
</template>

<script>
export default {
  props: ['message', 'readableTime', 'contactName'],
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';
.contact-name {
  font-size: $font-size-small;
  font-weight: $font-weight-light;
}
</style>
