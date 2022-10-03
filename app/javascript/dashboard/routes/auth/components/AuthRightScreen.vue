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
          <div class="testimonial-left--card testimonial-card absolute">
            <div class="left-card--wrap absolute">
              <div class="left-card--content">
                <p class="card-content">
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
          <div class="testimonial-right--card testimonial-card absolute">
            <div class="right-card--wrap absolute">
              <div class="right-card--content">
                <p class="card-content">
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
            class="reports-card absolute reports-left-card"
          />
          <img
            src="./assets/reports-right-card.svg"
            class="reports-card absolute reports-right-card"
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
@import '~dashboard/assets/scss/woot';

.absolute {
  position: absolute;
}

.image--wrap {
  background: #56b9fc;
  display: flex;
  flex: 1 1;

  .image {
    align-items: center;
    display: flex;
    flex: 1 1;
    justify-content: center;
    position: relative;

    .top-left--img {
      height: var(--space-giga);
      left: 0;
      top: 0;
      width: var(--space-giga);
    }

    .center-container {
      padding: var(--space-medium) 0;
      z-index: var(--z-index-low);
      .center--img {
        height: 72rem;
        width: 72rem;
      }
    }
    .bottom-right--img {
      bottom: 0;
      height: 28rem;
      right: 0;
      width: 28rem;
    }

    .image-bottom--text {
      align-items: center;
      display: flex;
      flex-direction: column;
      .heading {
        color: var(--white);
        font-weight: var(--font-weight-black);
        font-size: var(--font-size-bigger);
        margin-bottom: var(--space-small);
      }
      .sub-heading {
        color: var(--white);
        font-weight: var(--font-weight-bold);
      }
    }

    .testimonial-card {
      align-items: center;
      background: var(--white);
      box-shadow: var(--shadow-auth-page-card);
      border-radius: var(--border-radius-normal);
      display: flex;
      height: 26rem;
      justify-content: center;
      left: 50%;
      opacity: 0.92;
      top: 50%;
      width: 32rem;
    }

    .testimonial-left--card {
      transform: translate(-82%, 0%);
      .left-card--wrap {
        width: var(--space-giga);
        .left-card--content {
          color: var(--s-800);
          display: flex;
          flex-direction: column;
          justify-content: center;
          width: 100%;
        }
      }
    }
    .testimonial-right--card {
      transform: translate(-18%, -94%);
      .right-card--wrap {
        width: var(--space-giga);
        .right-card--content {
          color: var(--s-800);
          display: flex;
          flex-direction: column;
          justify-content: center;
          width: 100%;
        }
      }
    }

    .reports-card {
      left: 50%;
      top: 50%;
      width: 38rem;
    }

    .reports-left-card {
      transform: translate(-80%, 0%);
    }
    .reports-right-card {
      transform: translate(-20%, -92%);
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

@include breakpoint(xxxlarge up) {
  .image--wrap .image {
    .image-bottom--text {
      .heading {
        font-size: var(--font-size-mega);
      }
      .sub-heading {
        font-size: var(--font-size-medium);
      }
    }

    .content-author--details .author-name-company--details {
      .author-name {
        font-size: var(--font-size-default);
      }
      .author-company {
        font-size: var(--font-size-small);
      }
    }

    .center-container .center--img {
      height: 86rem;
      width: 86rem;
    }

    .reports-card {
      width: 44rem;
    }

    .testimonial-card {
      height: 30rem;
      width: 38rem;
      .card-content {
        font-size: var(--font-size-default);
      }
    }

    .testimonial-left--card .left-card--wrap {
      width: 28rem;
    }

    .testimonial-right--card .right-card--wrap {
      width: 28rem;
    }
  }
}
</style>
