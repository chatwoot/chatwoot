<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.CATEGORY.EDIT.TITLE')"
      :header-content="$t('HELP_CENTER.CATEGORY.EDIT.SUB_TITLE')"
    />
    <form class="row" @submit.prevent="onUpdate">
      <div class="medium-12 columns">
        <div class="row article-info">
          <div class="columns medium-6">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.EDIT.PORTAL') }}</span>
              <p class="value">{{ portalName }}</p>
            </label>
          </div>
          <div class="columns medium-6">
            <label>
              <span>{{ $t('HELP_CENTER.CATEGORY.EDIT.LOCALE') }}</span>
              <p class="value">{{ locale }}</p>
            </label>
          </div>
        </div>
        <woot-input
          v-model.trim="name"
          :class="{ error: $v.name.$error }"
          class="medium-12 columns"
          :error="nameError"
          :label="$t('HELP_CENTER.CATEGORY.EDIT.NAME.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.EDIT.NAME.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.EDIT.NAME.HELP_TEXT')"
          @input="onNameChange"
        />
        <woot-input
          v-model.trim="slug"
          :class="{ error: $v.slug.$error }"
          class="medium-12 columns"
          :error="slugError"
          :label="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.LABEL')"
          :placeholder="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.PLACEHOLDER')"
          :help-text="$t('HELP_CENTER.CATEGORY.EDIT.SLUG.HELP_TEXT')"
          @input="$v.slug.$touch"
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
        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
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

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required, minLength } from 'vuelidate/lib/validators';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

export default {
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
    category: {
      type: Object,
      default: () => {},
    },
    selectedPortalSlug: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      id: this.category.id,
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
  mounted() {
    this.updateDataFromStore();
  },
  methods: {
    updateDataFromStore() {
      const { category } = this;
      this.name = category.name;
      this.slug = category.slug;
      this.description = category.description;
    },
    onNameChange() {
      this.slug = convertToCategorySlug(this.name);
    },
    onUpdate() {
      this.$emit('update');
    },
    onClose() {
      this.$emit('cancel');
    },
    async editCategory() {
      const { id, name, slug, description } = this;
      const data = {
        id,
        name,
        slug,
        description,
      };
      this.$v.$touch();
      if (this.$v.$invalid) {
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
        this.$track(PORTALS_EVENTS.EDIT_CATEGORY);
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('HELP_CENTER.CATEGORY.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
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

.input-container::v-deep {
  margin: 0 0 var(--space-normal);

  input {
    margin-bottom: 0;
  }
}
</style>
