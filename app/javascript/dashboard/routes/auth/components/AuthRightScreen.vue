<template>
  <div class="image--wrap">
    <div class="image">
      <img src="./assets/top-left.svg" class="top-left--img absolute" />
      <div class="center-container">
        <div>
          <img src="./assets/background.svg" class="center--img" />
          <div v-show="showTestimonials" class="image-bottom--text">
            <h3 class="heading">
              {{ 'Loved by small and big teams, alike ' }}
            </h3>
            <span class="sub-block-title sub-heading">{{
              'We put your needs first. That is what keeps us going.'
            }}</span>
          </div>
          <div v-show="!showTestimonials" class="image-bottom--text">
            <h3 class="heading">{{ 'Get Realtime Reports ' }}</h3>
            <span class="sub-block-title sub-heading">{{
              'Stay on top of SLAs, agents, inboxes, multiple channels'
            }}</span>
          </div>
        </div>
        <div v-show="showTestimonials">
          <div class="testimonial-left--card testimonial-card">
            <img src="./assets/testimonials-left-card.svg" />
            <div class="left-card--wrap">
              <div class="left-card--content">
                <p>
                  {{ LEFT_CARD.AUTHOR_REVIEW }}
                </p>
                <div class="content-author--details row">
                  <div class="author-image--wrap">
                    <img :src="LEFT_CARD.AUTHOR_IMAGE" class="author-image" />
                  </div>
                  <div class="author-name-company--details">
                    <span class="author-name">
                      {{ LEFT_CARD.AUTHOR_NAME }}
                    </span>
                    <span class="author-company">{{
                      LEFT_CARD.AUTHOR_COMAPNY
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="testimonial-right--card testimonial-card">
            <img src="./assets/testimonials-left-card.svg" />
            <div class="right-card--wrap">
              <div class="right-card--content">
                <p>
                  {{ RIGHT_CARD.AUTHOR_REVIEW }}
                </p>
                <div class="content-author--details row">
                  <div class="author-image--wrap">
                    <img :src="RIGHT_CARD.AUTHOR_IMAGE" class="author-image" />
                  </div>
                  <div class="author-name-company--details">
                    <span class="author-name">
                      {{ RIGHT_CARD.AUTHOR_NAME }}
                    </span>
                    <span class="author-company">{{
                      RIGHT_CARD.AUTHOR_COMAPNY
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-show="!showTestimonials">
          <img
            src="./assets/reports-left-card.svg"
            class="reports-card reports-left-card"
          />
          <img
            src="./assets/reports-right-card.svg"
            class="reports-card reports-right-card"
          />
        </div>
      </div>
      <img src="./assets/bottom-right.svg" class="bottom-right--img absolute" />
    </div>
  </div>
</template>

<script>
import testimonialConstants from '../testimonialsConstants';
export default {
  data() {
    return {
      showTestimonials: false,
      timer: null,
      LEFT_CARD: testimonialConstants.LEFT_CARD,
      RIGHT_CARD: testimonialConstants.RIGHT_CARD,
    };
  },
  mounted() {
    this.switchImage();
  },
  beforeDestroy() {
    this.clearTimer();
  },
  methods: {
    switchImage() {
      this.timer = setTimeout(() => {
        this.showTestimonials = !this.showTestimonials;
        this.switchImage();
      }, 5000);
    },
    clearTimer() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.image--wrap {
  display: flex;
  flex: 1 1;
  background: #56b9fc;

  .absolute {
    position: absolute;
  }

  .image {
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    flex: 1 1;

    .top-left--img {
      width: 24rem;
      height: 24rem;
      top: 0;
      left: 0;
    }

    .center-container {
      padding: var(--space-medium) 0;
      .center--img {
        width: 70rem;
        height: 70rem;
      }
    }
    .bottom-right--img {
      width: 28rem;
      height: 28rem;
      right: 0;
      bottom: 0;
    }

    .image-bottom--text {
      display: flex;
      flex-direction: column;
      align-items: center;
      .heading {
        font-weight: var(--font-weight-black);
        margin-bottom: var(--space-small);
        font-size: var(--font-size-bigger);
        color: var(--white);
      }
      .sub-heading {
        font-weight: var(--font-weight-bold);
        color: var(--white);
      }
    }

    .testimonial-card {
      position: absolute;
      width: 30rem;
      top: 50%;
      left: 50%;
      align-items: center;
      display: flex;
      justify-content: center;
    }

    .testimonial-left--card {
      transform: translate(-90%, 0%);

      .left-card--wrap {
        width: 24rem;
        position: absolute;

        .left-card--content {
          display: flex;
          justify-content: center;
          flex-direction: column;
          color: var(--s-800);
          width: 100%;
        }
      }
    }
    .testimonial-right--card {
      transform: translate(-24%, -82%);

      .right-card--wrap {
        width: 24rem;
        position: absolute;

        .right-card--content {
          display: flex;
          justify-content: center;
          flex-direction: column;
          color: var(--s-800);
          width: 100%;
        }
      }
    }

    .reports-card {
      top: 50%;
      left: 50%;
      position: absolute;
      width: 36rem;
    }

    .reports-left-card {
      transform: translate(-84%, 0%);
    }
    .reports-right-card {
      transform: translate(-25%, -90%);
    }

    .content-author--details {
      display: flex;
      align-items: center;
      margin-top: var(--space-smaller);

      .author-image--wrap {
        padding: var(--space-smaller);
        background: white;
        border-radius: var(--border-radius-rounded);
        .author-image {
          width: 4rem;
          height: 4rem;
          border-radius: var(--border-radius-rounded);
        }
      }

      .author-name-company--details {
        display: flex;
        flex-direction: column;
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
  }
}

@media screen and (max-width: 1200px) {
  .image--wrap {
    display: none;
  }
}
</style>
