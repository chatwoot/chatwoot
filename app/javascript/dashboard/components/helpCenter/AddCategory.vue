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
          v-model.trim="name"
          :class="{ error: $v.name.$error }"
          class="medium-12 columns"
          :error="nameError"
          :label="$t('HELP_CENTER.CATEGORY.ADD.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.NAME.HELP_TEXT')"
          @input="onNameChange"
        />
        <woot-input
          v-model.trim="slug"
          :class="{ error: $v.slug.$error }"
          class="medium-12 columns"
          :error="slugError"
          :label="$t('HELP_CENTER.CATEGORY.ADD.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.ADD.SLUG.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.ADD.SLUG.HELP_TEXT')"
          @input="$v.slug.$touch"
        />
        <label :class="{ error: $v.description.$error }">
          {{ $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.LABEL') }}
          <textarea
            v-model="description"
            rows="3"
            type="text"
            :placeholder="
              $t('HELP_CENTER.CATEGORY.ADD.DESCRIPTION.PLACEHOLDER')
            "
            @blur="$v.description.$touch"
          />
          <span v-if="$v.description.$error" class="message">
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
import { convertToCategorySlug } from 'dashboard/helper/commons.js';

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
      name: '',
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
    description: {
      required,
    },
  },
  computed: {
    nameError() {
      if (this.$v.name.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.NAME.ERROR');
      }
      return '';
    },
    slugError() {
      if (this.$v.slug.$error) {
        return this.$t('HELP_CENTER.CATEGORY.ADD.SLUG.ERROR');
      }
      return '';
    },
  },
  methods: {
    onNameChange() {
      this.slug = convertToCategorySlug(this.name);
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
      this.name = '';
      this.slug = '';
      this.description = '';
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
