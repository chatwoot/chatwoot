<script setup>
import Avatar from 'next/avatar/Avatar.vue';

defineProps({
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
});
</script>

<template>
  <div class="option-item--user">
    <Avatar :src="thumbnail" :size="28" :name="name" rounded-full />
    <div class="option__user-data">
      <h5 class="option__title">
        {{ name }}
        <span v-if="identifier" class="user-identifier">
          {{ $t('MERGE_CONTACTS.DROPDOWN_ITEM.ID', { identifier }) }}
        </span>
      </h5>
      <p class="option__body">
        <span v-if="email" class="email-icon-wrap">
          <fluent-icon class="merge-contact--icon" icon="mail" size="12" />
          {{ email }}
        </span>
        <span v-if="phoneNumber" class="phone-icon-wrap">
          <fluent-icon class="merge-contact--icon" icon="call" size="12" />
          {{ phoneNumber }}
        </span>
        <span v-if="!phoneNumber && !email">{{ '---' }}</span>
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.option-item--user {
  @apply flex items-center;
}
.user-identifier {
  @apply text-xs ml-0.5 text-n-slate-12;
}
.option__user-data {
  @apply flex flex-col flex-grow ml-2 mr-2;
}
.option__body,
.option__title {
  @apply flex items-center justify-start leading-[1.2] text-sm;
}
.option__body .icon {
  @apply relative top-px mr-0.5 rtl:mr-0 rtl:ml-0.5;
}
.option__title {
  @apply text-n-slate-12 font-medium mb-0.5;
}
.option__body {
  @apply text-xs text-n-slate-12 mt-1;
}

.option__user-data .option__body {
  > .phone-icon-wrap,
  > .email-icon-wrap {
    @apply w-auto flex items-center;
  }
}

.merge-contact--icon {
  @apply -mb-0.5 mr-0.5;
}
</style>
