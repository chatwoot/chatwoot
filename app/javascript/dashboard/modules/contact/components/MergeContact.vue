<template>
  <form @submit.prevent="onSubmit">
    <div class="merge-contacts">
      <div class="multiselect-wrap--medium">
        <label class="multiselect__label">
          {{ $t('MERGE_CONTACTS.PRIMARY.TITLE') }}
          <woot-label
            :title="$t('MERGE_CONTACTS.PRIMARY.HELP_LABEL')"
            color-scheme="success"
            small
            class="label--merge-warning"
          />
        </label>
        <multiselect
          :value="primaryContact"
          disabled
          :options="[]"
          :show-labels="false"
          label="name"
          track-by="id"
        >
          <template slot="singleLabel" slot-scope="props">
            <contact-dropdown-item
              :thumbnail="props.option.thumbnail"
              :name="props.option.name"
              :identifier="props.option.id"
              :email="props.option.email"
              :phone-number="props.option.phoneNumber"
            />
          </template>
        </multiselect>
      </div>

      <div class="child-contact-wrap">
        <div class="child-arrow">
          <fluent-icon icon="arrow-up" class="up" size="17" />
        </div>
        <div
          class="child-contact multiselect-wrap--medium"
          :class="{ error: $v.childContact.$error }"
        >
          <label class="multiselect__label">
            {{ $t('MERGE_CONTACTS.CHILD.TITLE')
            }}<woot-label
              :title="$t('MERGE_CONTACTS.CHILD.HELP_LABEL')"
              color-scheme="alert"
              small
              class="label--merge-warning"
            />
          </label>
          <multiselect
            v-model="childContact"
            :options="searchResults"
            label="name"
            track-by="id"
            :internal-search="false"
            :clear-on-select="false"
            :show-labels="false"
            :placeholder="$t('MERGE_CONTACTS.CHILD.PLACEHOLDER')"
            :allow-empty="true"
            :loading="isSearching"
            :max-height="150"
            open-direction="top"
            @search-change="searchChange"
          >
            <template slot="singleLabel" slot-scope="props">
              <contact-dropdown-item
                :thumbnail="props.option.thumbnail"
                :identifier="props.option.id"
                :name="props.option.name"
                :email="props.option.email"
                :phone-number="props.option.phone_number"
              />
            </template>
            <template slot="option" slot-scope="props">
              <contact-dropdown-item
                :thumbnail="props.option.thumbnail"
                :identifier="props.option.id"
                :name="props.option.name"
                :email="props.option.email"
                :phone-number="props.option.phone_number"
              />
            </template>
            <span slot="noResult">
              {{ $t('AGENT_MGMT.SEARCH.NO_RESULTS') }}
            </span>
          </multiselect>
          <span v-if="$v.childContact.$error" class="message">
            {{ $t('MERGE_CONTACTS.FORM.CHILD_CONTACT.ERROR') }}
          </span>
        </div>
      </div>
    </div>
    <merge-contact-summary
      :primary-contact-name="primaryContact.name"
      :child-contact-name="childContactName"
    />
    <div class="footer">
      <woot-button variant="clear" @click.prevent="onCancel">
        {{ $t('MERGE_CONTACTS.FORM.CANCEL') }}
      </woot-button>
      <woot-button type="submit" :is-loading="isMerging">
        {{ $t('MERGE_CONTACTS.FORM.SUBMIT') }}
      </woot-button>
    </div>
  </form>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';

import MergeContactSummary from 'dashboard/modules/contact/components/MergeContactSummary';
import ContactDropdownItem from './ContactDropdownItem';

export default {
  components: { MergeContactSummary, ContactDropdownItem },
  mixins: [alertMixin],
  props: {
    primaryContact: {
      type: Object,
      required: true,
    },
    isSearching: {
      type: Boolean,
      default: false,
    },
    isMerging: {
      type: Boolean,
      default: false,
    },
    searchResults: {
      type: Array,
      default: () => [],
    },
  },
  validations: {
    primaryContact: {
      required,
    },
    childContact: {
      required,
    },
  },
  data() {
    return {
      childContact: undefined,
    };
  },

  computed: {
    childContactName() {
      return this.childContact ? this.childContact.name : '';
    },
  },
  methods: {
    searchChange(query) {
      this.$emit('search', query);
    },
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$emit('submit', this.childContact.id);
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
};
</script>

<style lang="scss" scoped>
.child-contact-wrap {
  @apply flex w-full;
}
.child-contact {
  @apply min-w-0 flex-grow flex-shrink-0;
}
.child-arrow {
  @apply w-8 relative text-base text-slate-100 dark:text-slate-600;
}
.multiselect {
  @apply mb-2;
}
.child-contact {
  @apply mt-1;
}
.child-arrow::after {
  @apply content-[''] h-12 w-0 left-5 absolute border-l border-solid border-slate-100 dark:border-slate-600;
}

.child-arrow::before {
  @apply content-[''] h-0 w-4 left-5 top-12 absolute border-b border-solid border-slate-100 dark:border-slate-600;
}

.up {
  @apply absolute -top-1 left-3;
}

.footer {
  @apply mt-6 flex justify-end;
}

/* TDOD: Clean errors in forms style */
.error .message {
  @apply mt-0;
}

.label--merge-warning {
  @apply ml-2;
}

::v-deep {
  .multiselect {
    @apply rounded-md;
  }

  .multiselect__tags {
    @apply h-[52px];
  }
}
</style>
