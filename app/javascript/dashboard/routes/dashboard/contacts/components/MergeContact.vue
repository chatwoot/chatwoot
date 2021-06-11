<template>
  <div class="merge-contacts">
    <h5 class="sub-block-title">{{ $t('MERGE_CONTACTS.TITLE') }}</h5>
    <div class="wrap">
      <div class="multiselect-wrap--small">
        <label class="multiselect__label">
          {{ $t('MERGE_CONTACTS.PRIMARY.TITLE') }}
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
            <thumbnail
              :src="props.option.thumbnail"
              size="24px"
              :username="props.option.name"
            />
            <span class="option__title">
              {{ props.option.name }}
            </span>
          </template>
        </multiselect>

        <div class="child-contact-wrap">
          <div class="child-arrow">
            <i class="ion-ios-arrow-up up" />
          </div>
          <div class="child-contact">
            <label class="multiselect__label">
              {{ $t('MERGE_CONTACTS.CHILD.TITLE') }}
            </label>
            <multiselect
              :options="options"
              label="name"
              track-by="id"
              :internal-search="false"
              :clear-on-select="false"
              :show-labels="false"
              placeholder="Choose a contact"
              :allow-empty="true"
              :loading="isSearching"
              @search-change="asyncFind"
            >
              <template slot="singleLabel" slot-scope="props">
                <thumbnail
                  :src="props.option.thumbnail"
                  size="24px"
                  :username="props.option.name"
                />
                <span class="option__title">
                  {{ props.option.name }}
                </span>
              </template>
              <span slot="noResult">{{
                $t('AGENT_MGMT.SEARCH.NO_RESULTS')
              }}</span>
            </multiselect>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: { Thumbnail },
  mixins: [alertMixin],
  props: {
    primaryContact: {
      type: Object,
      required: true,
    },
    onContactSearch: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      isSearching: false,
      searchResults: [],
      value: {
        name: 'Micheal Scott',
        id: 11,
        thumbnail: 'https://randomuser.me/api/portraits/men/47.jpg',
      },
      options: [],
    };
  },
  computed: {
    readableTime() {
      return this.dynamicTime(this.timeStamp);
    },
  },

  methods: {
    async asyncFind(query) {
      this.isSearching = true;
      try {
        const result = await this.onContactSearch(query);
        this.searchResults = result;
      } catch (error) {
        this.showAlert('Something went wrong!');
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.wrap {
  margin-top: var(--space-smaller);
}
.child-contact-wrap {
  display: flex;
  width: 100%;
}
.child-contact {
  flex: 1 0 0;
  min-width: 0;
}
.child-arrow {
  width: var(--space-larger);
  position: relative;
  font-size: var(--font-size-default);
  color: var(--color-border-dark);
}
.multiselect {
  margin-bottom: var(--space-small);
}
.child-contact {
  margin-top: var(--space-smaller);
}
.child-arrow::after {
  content: '';
  height: var(--space-larger);
  width: 0;
  left: var(--space-two);
  position: absolute;
  border-left: 1px solid var(--color-border-dark);
}

.child-arrow::before {
  content: '';
  height: 0;
  width: var(--space-normal);
  left: var(--space-two);
  top: var(--space-larger);
  position: absolute;
  border-bottom: 1px solid var(--color-border-dark);
}

.up {
  position: absolute;
  top: -11px;
  left: var(--space-normal);
}

::v-deep .multiselect__tags .option__title {
  display: inline-flex;
  align-items: center;
  margin-left: var(--space-small);
}
</style>
