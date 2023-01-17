<template>
  <div class="testimonial--footer">
    <h2 class="heading">
      {{ title }}
    </h2>
    <span class="sub-block-title sub-heading">
      {{ subTitle }}
    </span>
  </div>
</template>
<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
  },
};
</script>
<style scoped lang="scss">
.testimonial--footer {
  align-items: center;
  bottom: var(--space-jumbo);
  display: flex;
  flex-direction: column;
  text-align: center;
  margin: 0 auto;
  padding: 0 var(--space-jumbo);
  position: absolute;
  width: 100%;

  .heading {
    color: var(--white);
    font-size: var(--font-size-bigger);
  }

  .sub-heading {
    color: var(--white);
    font-weight: var(--font-weight-medium);
  }
}
</style>
