<template>
  <div class="option-item--user">
    <thumbnail :src="thumbnail" size="28px" :username="name" />
    <div class="option__user-data">
      <h5 class="option__title">
        {{ name }}
        <span v-if="identifier" class="user-identifier">
          (ID: {{ identifier }})
        </span>
      </h5>
      <p class="option__body">
        <span v-if="email" class="email-icon-wrap">
          <i class="icon ion-email" />{{ email }}
        </span>
        <span v-if="phoneNumber" class="phone-icon-wrap">
          <i class="icon ion-ios-telephone" />
          {{ phoneNumber }}
        </span>
        <span v-if="!phoneNumber && !email">{{ '---' }}</span>
      </p>
    </div>
  </div>
</template>

<script>
import Thumbnail from '../../../components/widgets/Thumbnail';

export default {
  components: {
    Thumbnail,
  },
  props: {
    name: {
      type: String,
      default: '',
    },
    thumbnail: {
      type: String,
      default: '',
    },
    email: {
      type: String,
      default: '',
    },
    phoneNumber: {
      type: String,
      default: '',
    },
    identifier: {
      type: [String, Number],
      required: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.option-item--user {
  display: flex;
  align-items: center;
}
.user-identifier {
  font-size: var(--font-size-mini);
  margin-left: var(--space-micro);
  color: var(--s-700);
}
.option__user-data {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  margin-left: var(--space-small);
}
.option__body,
.option__title {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  line-height: 1.2;
  font-size: var(--font-size-small);
}
.option__body .icon {
  position: relative;
  top: 1px;
  margin-right: var(--space-micro);
}
.option__title {
  font-weight: var(--font-weight-medium);
  margin-bottom: var(--space-micro);
}
.option__body {
  font-size: var(--font-size-mini);
  color: var(--s-700);
}

.email-icon-wrap {
  margin-right: var(--space-normal);
}

.option__user-data .option__body {
  > .phone-icon-wrap,
  > .email-icon-wrap {
    width: auto;
  }
}
</style>
