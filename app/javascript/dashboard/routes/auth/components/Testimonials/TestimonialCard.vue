<template>
  <div class="testimonial-card">
    <div class="left-card--wrap absolute">
      <div class="left-card--content">
        <p class="card-content">
          {{ reviewContent }}
        </p>
        <div class="content-author--details row">
          <div class="author-image--wrap">
            <img :src="authorImage" class="author-image" />
          </div>
          <div class="author-name-company--details">
            <div class="author-name">{{ authorName }}</div>
            <div class="author-company">{{ authorDesignation }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    reviewContent: {
      type: String,
      default: '',
    },
    authorImage: {
      type: String,
      default: '',
    },
    authorName: {
      type: String,
      default: '',
    },
    authorDesignation: {
      type: String,
      default: '',
    },
  },
  setup() {},
};
</script>

<style scoped lang="scss">
.testimonial-card {
  align-items: center;
  background: var(--white);
  border-radius: var(--border-radius-normal);
  box-shadow: var(--shadow-large);
  display: flex;
  justify-content: center;
  padding: var(--space-medium) var(--space-large);
  width: 32rem;
}

.content-author--details {
  align-items: center;
  display: flex;
  margin-top: var(--space-small);

  .author-image--wrap {
    background: white;
    border-radius: var(--border-radius-rounded);
    padding: var(--space-smaller);

    .author-image {
      border-radius: var(--border-radius-rounded);
      height: calc(var(--space-two) + var(--space-two));
      width: calc(var(--space-two) + var(--space-two));
    }
  }

  .author-name-company--details {
    margin-left: var(--space-small);

    .author-name {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-bold);
    }

    .author-company {
      font-size: var(--font-size-mini);
    }
  }
}

.card-content {
  color: var(--s-600);
  // font-size: var(--font-size-default);
  line-height: 1.7;
}
</style>
