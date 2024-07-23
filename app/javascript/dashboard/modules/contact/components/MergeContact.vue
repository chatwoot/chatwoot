<template>
  <form @submit.prevent="onSubmit">
    <div>
      <div>
        <div
          class="mt-1 multiselect-wrap--medium"
          :class="{ error: $v.parentContact.$error }"
        >
          <label class="multiselect__label">
            {{ $t('MERGE_CONTACTS.PARENT.TITLE') }}
            <woot-label
              :title="$t('MERGE_CONTACTS.PARENT.HELP_LABEL')"
              color-scheme="success"
              small
              class="ml-2"
            />
          </label>
          <multiselect
            v-model="parentContact"
            :options="searchResults"
            label="name"
            track-by="id"
            :internal-search="false"
            :clear-on-select="false"
            :show-labels="false"
            :placeholder="$t('MERGE_CONTACTS.PARENT.PLACEHOLDER')"
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
          <span v-if="$v.parentContact.$error" class="message">
            {{ $t('MERGE_CONTACTS.FORM.CHILD_CONTACT.ERROR') }}
          </span>
        </div>
      </div>
      <div class="flex multiselect-wrap--medium">
        <div
          class="w-8 relative text-base text-slate-100 dark:text-slate-600 after:content-[''] after:h-12 after:w-0 after:left-4 after:absolute after:border-l after:border-solid after:border-slate-100 after:dark:border-slate-600 before:content-[''] before:h-0 before:w-4 before:left-4 before:top-12 before:absolute before:border-b before:border-solid before:border-slate-100 before:dark:border-slate-600"
        >
          <fluent-icon
            icon="arrow-up"
            class="absolute -top-1 left-2"
            size="17"
          />
        </div>
        <div class="flex flex-col w-full">
          <label class="multiselect__label">
            {{ $t('MERGE_CONTACTS.PRIMARY.TITLE') }}
            <woot-label
              :title="$t('MERGE_CONTACTS.PRIMARY.HELP_LABEL')"
              color-scheme="alert"
              small
              class="ml-2"
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
      </div>
    </div>
    <merge-contact-summary
      :primary-contact-name="primaryContact.name"
      :parent-contact-name="parentContactName"
    />
    <div class="flex justify-end gap-2 mt-6">
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
import { required } from 'vuelidate/lib/validators';

import MergeContactSummary from 'dashboard/modules/contact/components/MergeContactSummary.vue';
import ContactDropdownItem from './ContactDropdownItem.vue';

export default {
  components: { MergeContactSummary, ContactDropdownItem },
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
    parentContact: {
      required,
    },
  },
  data() {
    return {
      parentContact: undefined,
    };
  },

  computed: {
    parentContactName() {
      return this.parentContact ? this.parentContact.name : '';
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
      this.$emit('submit', this.parentContact.id);
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
};
</script>

<style lang="scss" scoped>
/* TDOD: Clean errors in forms style */
.error .message {
  @apply mt-0;
}

::v-deep {
  .multiselect {
    @apply rounded-md;
  }

  .multiselect--disabled {
    @apply border-0;

    .multiselect__tags {
      @apply border;
    }
  }

  .multiselect__tags {
    @apply h-[52px];
  }
}
</style>
