<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.CATEGORY.ADD.TITLE')"
      :header-content="$t('HELP_CENTER.CATEGORY.ADD.SUB_TITLE')"
    />
    <form class="w-full" @submit.prevent="onCreate">
      <div class="w-full">
        <div class="flex flex-row w-full mx-0 mt-0 mb-4">
          <div class="w-[50%]">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.ADD.PORTAL') }}</span>
              <p class="text-slate-600 dark:text-slate-400">{{ portalName }}</p>
            </label>
          </div>
          <div class="w-[50%]">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.ADD.LOCALE') }}</span>
              <p class="text-slate-600 dark:text-slate-400">{{ locale }}</p>
            </label>
          </div>
        </div>
        <category-name-icon-input
          :label="$t('HELP_CENTER.CATEGORY.ADD.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.NAME.HELP_TEXT')"
          :has-error="$v.name.$error"
          :error-message="$t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR')"
          @name-change="onNameChange"
          @icon-change="onClickInsertEmoji"
        />
        <woot-input
          v-model.trim="slug"
          :class="{ error: $v.slug.$error }"
          class="w-full"
          :error="slugError"
          :label="$t('HELP_CENTER.CATEGORY.ADD.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.SLUG.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.SLUG.HELP_TEXT')"
          @input="$v.slug.$touch"
        />
        <label>
          {{ $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.LABEL') }}
          <textarea
            v-model="description"
            rows="3"
            type="text"
            :placeholder="
              $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.PLACEHOLDER')
            "
          />
        </label>
        <div class="w-full">
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('HELP_CENTER.CATEGORY.ADD.BUTTONS.CANCEL') }}
            </woot-button>
            <woot-button @click="addCategory">
              {{ $t('HELP_CENTER.CATEGORY.ADD.BUTTONS.CREATE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </form>
  </woot-modal>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import { required, minLength } from 'vuelidate/lib/validators';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';
import CategoryNameIconInput from './NameEmojiInput.vue';

export default {
  components: { CategoryNameIconInput },
  props: {
    show: {
      type: Boolean,
      default: true,
    },
    portalName: {
      type: String,
      default: '',
    },
    locale: {
      type: String,
      default: '',
    },
    portalSlug: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      name: '',
      icon: '',
      slug: '',
      description: '',
    };
  },
  validations: {
    name: {
      required,
      minLength: minLength(2),
    },
    slug: {
      required,
    },
  },
  computed: {
    selectedPortalSlug() {
      return this.$route.params.portalSlug
        ? this.$route.params.portalSlug
        : this.portalSlug;
    },
    slugError() {
      if (this.$v.slug.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
      }
      return '';
    },
  },
  methods: {
    onNameChange(name) {
      this.name = name;
      this.slug = convertToCategorySlug(this.name);
    },
    onCreate() {
      this.$emit('create');
    },
    onClose() {
      this.$emit('cancel');
    },
    onClickInsertEmoji(emoji) {
      this.icon = emoji;
    },

    async addCategory() {
      const { name, slug, description, locale, icon } = this;
      const data = {
        name,
        icon,
        slug,
        description,
        locale,
      };
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('categories/create', {
          portalSlug: this.selectedPortalSlug,
          categoryObj: data,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.CATEGORY.ADD.API.SUCCESS_MESSAGE'
        );
        this.onClose();
        this.$track(PORTALS_EVENTS.CREATE_CATEGORY, {
          hasDescription: Boolean(description),
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('HELP_CENTER.CATEGORY.ADD.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>
<style scoped lang="scss">
.input-container::v-deep {
  @apply mt-0 mb-4 mx-0;

  input {
    @apply mb-0;
  }
}
</style>
