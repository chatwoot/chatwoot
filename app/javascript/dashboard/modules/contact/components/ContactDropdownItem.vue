<template>
  <div class="option-item--user">
    <thumbnail :src="thumbnail" size="28px" :username="name" />
    <div class="option__user-data">
      <h5 class="option__title">
        {{ name }}
        <span v-if="identifier" class="user-identifier">
          ( id: {{ identifier }} )
        </span>
      </h5>
      <p class="option__body">
        <span v-if="email"><i class="icon ion-email" />{{ email }}</span>
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
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
.option-item--user {
  display: flex;
}
.user-identifier {
  font-size: var(--font-size-mini);
  margin-left: var(--space-smaller);
  color: var(--s-700);
}
.option__user-data {
  display: flex;
  flex-direction: column;
}
.option__body,
.option__title {
  display: block;
  line-height: 1.2;
  font-size: var(--font-size-small);
}
.option__body .icon {
  margin-right: var(--space-micro);
}
.option__title {
  font-weight: var(--font-weight-medium);
  margin-bottom: var(--space-micro);
}
.option__body {
  font-size: var(--font-size-mini);
  margin-left: var(--space-small);
  color: var(--s-700);
}
.phone-icon-wrap {
  margin-left: var(--space-small);
}
</style>
