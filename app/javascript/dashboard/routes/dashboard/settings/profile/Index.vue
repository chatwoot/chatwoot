<template>
  <div class="columns profile--settings ">
    <form @submit.prevent="createChannel()">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3 ">
          <p class="section--title">
            {{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.TITLE') }}
          </p>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9">
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.PROFILE_IMAGE.LABEL') }}
            <thumbnail size="80px"></thumbnail>
            <input
              id="file"
              ref="file"
              type="file"
              accept="image/*"
              @change="handleImageUpload()"
            />
          </label>
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model.trim="name"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
            />
          </label>
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="email"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
            />
          </label>
        </div>
        <button
          class="button nice success button--fixed-right-top"
          @click="updateUser()"
        >
          {{ $t('PROFILE_SETTINGS.BTN_TEXT') }}
        </button>
      </div>
      <div class="profile--settings--row row">
        <div class="columns small-3 ">
          <p class="section--title">
            {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
          </p>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9">
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model.trim="name"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
            />
          </label>
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="email"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
            />
          </label>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  methods: {
    updateUser() {},
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings {
  padding: 24px;
}

.profile--settings--row {
  @include border-normal-bottom;
  padding: 16px;
  .small-3 {
    padding: 16px 16px 16px 0;
  }
  .small-9 {
    padding: 16px;
  }
}

.section--title {
  color: $color-woot;
}
</style>
