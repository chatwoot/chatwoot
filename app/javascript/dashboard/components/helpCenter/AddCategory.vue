<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.CATEGORY.ADD.TITLE')"
      :header-content="$t('HELP_CENTER.CATEGORY.ADD.SUB_TITLE')"
    />
    <form class="row" @submit.prevent="onCreate">
      <div class="medium-12 columns">
        <div class="row article-info">
          <div class="columns medium-6">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.ADD.PORTAL') }}</span>
              <p class="value">{{ portalName }}</p>
            </label>
          </div>
          <div class="columns medium-6">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.ADD.LOCALE') }}</span>
              <p class="value">{{ locale }}</p>
            </label>
          </div>
        </div>
        <woot-input
          v-model.trim="categoryName"
          :class="{ error: $v.categoryName.$error }"
          class="medium-12 columns"
          :error="categoryNameError"
          :label="$t('HELP_CENTER.CATEGORY.ADD.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.NAME.HELP_TEXT')"
          @input="onCategoryNameChange"
        />
        <woot-input
          v-model.trim="categorySlug"
          :class="{ error: $v.categorySlug.$error }"
          class="medium-12 columns"
          :error="categorySlugError"
          :label="$t('HELP_CENTER.CATEGORY.ADD.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.SLUG.HELP_TEXT')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.SLUG.HELP_TEXT')"
          @input="$v.categorySlug.$touch"
        />
        <label :class="{ error: $v.categoryDescription.$error }">
          {{ $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.LABEL') }}
          <textarea
            v-model="categoryDescription"
            rows="3"
            type="text"
            :placeholder="
              $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.PLACEHOLDER')
            "
            @blur="$v.categoryDescription.$touch"
          />
          <span v-if="$v.categoryDescription.$error" class="message">
            {{ $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.ERROR') }}
          </span>
        </label>
        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('HELP_CENTER.CATEGORY.ADD.BUTTONS.CANCEL') }}
            </woot-button>
            <woot-button>
              {{ $t('HELP_CENTER.CATEGORY.ADD.BUTTONS.CREATE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from 'dashboard/components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import { required, minLength } from 'vuelidate/lib/validators';
import { convertToSlug } from 'dashboard/helper/commons.js';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: true,
    },
    isCreating: {
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
  },
  data() {
    return {
      categorySlug: '',
      categoryName: '',
      categoryDescription: '',
    };
  },
  validations: {
    categoryName: {
      required,
      minLength: minLength(2),
    },
    categorySlug: {
      required,
    },
    categoryDescription: {
      required,
    },
  },
  computed: {
    categoryNameError() {
      if (this.$v.categoryName.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR');
      }
      return '';
    },
    categorySlugError() {
      if (this.$v.categorySlug.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
      }
      return '';
    },
  },
  methods: {
    onCategoryNameChange() {
      this.categorySlug = convertToSlug(this.categoryName);
    },
    onCreate() {
      this.$emit('create');
      this.reset();
      this.$emit('cancel');
    },
    onClose() {
      this.reset();
      this.$emit('cancel');
    },
    reset() {
      this.categoryName = '';
      this.categorySlug = '';
    },
  },
};
</script>
<style scoped lang="scss">
.article-info {
  width: 100%;
  margin: 0 0 var(--space-normal);
  .value {
    color: var(--s-600);
  }
}
</style>
