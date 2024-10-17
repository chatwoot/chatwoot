<script>
import { required, minLength } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useAlert, useTrack } from 'dashboard/composables';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';
import CategoryNameIconInput from './NameEmojiInput.vue';

export default {
  components: { CategoryNameIconInput },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    portalName: {
      type: String,
      default: '',
    },
    locale: {
      type: String,
      default: '',
    },
    category: {
      type: Object,
      default: () => {},
    },
    selectedPortalSlug: {
      type: String,
      default: '',
    },
  },
  emits: ['update', 'cancel', 'update:show'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      id: this.category.id,
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
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    slugError() {
      if (this.v$.slug.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
      }
      return '';
    },
  },
  mounted() {
    this.updateDataFromStore();
  },
  methods: {
    updateDataFromStore() {
      const { category } = this;
      this.name = category.name;
      this.icon = category.icon;
      this.slug = category.slug;
      this.description = category.description;
    },
    changeName(name) {
      this.name = name;
      this.slug = convertToCategorySlug(this.name);
    },
    onClickInsertEmoji(emoji) {
      this.icon = emoji;
    },
    onUpdate() {
      this.$emit('update');
    },
    onClose() {
      this.$emit('cancel');
    },
    async editCategory() {
      const { id, name, slug, icon, description } = this;
      const data = {
        id,
        name,
        icon,
        slug,
        description,
      };
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('categories/update', {
          portalSlug: this.selectedPortalSlug,
          categoryId: id,
          categoryObj: data,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.CATEGORY.EDIT.API.SUCCESS_MESSAGE'
        );
        useTrack(PORTALS_EVENTS.EDIT_CATEGORY);
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('HELP_CENTER.CATEGORY.EDIT.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.CATEGORY.EDIT.TITLE')"
      :header-content="$t('HELP_CENTER.CATEGORY.EDIT.SUB_TITLE')"
    />
    <form class="w-full" @submit.prevent="onUpdate">
      <div class="w-full">
        <div class="flex flex-row w-full mx-0 mt-0 mb-4">
          <div class="w-[50%]">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.EDIT.PORTAL') }}</span>
              <p class="text-slate-600 dark:text-slate-400">{{ portalName }}</p>
            </label>
          </div>
          <div class="w-[50%]">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.EDIT.LOCALE') }}</span>
              <p class="text-slate-600 dark:text-slate-400">{{ locale }}</p>
            </label>
          </div>
        </div>
        <CategoryNameIconInput
          :label="$t('HELP_CENTER.CATEGORY.EDIT.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.EDIT.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.EDIT.NAME.HELP_TEXT')"
          :has-error="v$.name.$error"
          :error-message="$t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR')"
          :existing-name="category.name"
          :saved-icon="category.icon"
          @name-change="changeName"
          @icon-change="onClickInsertEmoji"
        />
        <woot-input
          v-model="slug"
          :class="{ error: v$.slug.$error }"
          class="w-full"
          :error="slugError"
          :label="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.HELP_TEXT')"
          @input="v$.slug.$touch"
          @blur="v$.slug.$touch"
        />
        <label>
          {{ $t('HELP_CENTER.CATEGORY.EDIT.DESCRIPTION.LABEL') }}
          <textarea
            v-model="description"
            rows="3"
            type="text"
            :placeholder="
              $t('HELP_CENTER.CATEGORY.EDIT.DESCRIPTION.PLACEHOLDER')
            "
          />
        </label>
        <div class="w-full">
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('HELP_CENTER.CATEGORY.EDIT.BUTTONS.CANCEL') }}
            </woot-button>
            <woot-button @click="editCategory">
              {{ $t('HELP_CENTER.CATEGORY.EDIT.BUTTONS.CREATE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </form>
  </woot-modal>
</template>

<style scoped lang="scss">
.article-info {
  width: 100%;
  margin: 0 0 var(--space-normal);

  .value {
    color: var(--s-600);
  }
}

.input-container::v-deep {
  margin: 0 0 var(--space-normal);

  input {
    margin-bottom: 0;
  }
}
</style>
