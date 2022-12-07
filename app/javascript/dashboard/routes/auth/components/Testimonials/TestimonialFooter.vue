<template>
  <div class="testimonial--footer">
    <h2 class="heading">
      {{ title }}
    </h2>
    <span class="block-title sub-heading">
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
  display: flex;
  flex-direction: column;

  .heading {
    color: var(--white);
    font-weight: var(--font-weight-bold);
    text-align: center;
  }

  .sub-heading {
    color: var(--white);
    font-weight: var(--font-weight-medium);
  }
}
</style>
