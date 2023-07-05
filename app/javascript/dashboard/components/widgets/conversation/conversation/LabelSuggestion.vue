<template>
  <li v-if="shouldShowSuggestions" class="label-suggestion right">
    <div class="wrap">
      <div class="label-suggestion--container">
        <h6 class="label-suggestion--title">Suggested labels</h6>
        <div v-if="!fetchingSuggestions" class="label-suggestion--options">
          <button
            v-for="label in preparedLabels"
            :key="label.title"
            @click="addLabel(label.title)"
          >
            <woot-label
              variant="smooth"
              :dashed="true"
              v-bind="label"
              :bg-color="
                selectedLabels.includes(label.title) ? 'var(--w-100)' : ''
              "
            />
          </button>
        </div>
        <woot-button
          variant="smooth"
          class="label--add"
          icon="add"
          size="tiny"
          @click="addAllLabels"
        >
          <template v-if="selectedLabels.length === 0">
            Add all labels
          </template>
          <template v-else>
            Add selected labels
          </template>
        </woot-button>
      </div>
      <div class="sender--info has-tooltip" data-original-title="null">
        <woot-thumbnail size="16px">
          <avatar class="user-thumbnail thumbnail-rounded">
            <!-- replace with icon -->
            <svg
              v-once
              width="10"
              height="10"
              viewBox="0 0 10 10"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M3 2L2.864 2.00933C2.6246 2.0422 2.40519 2.16064 2.24636 2.34276C2.08752 2.52488 2.00001 2.75835 2 3V4H0.999999L0.864001 4.00933C0.624596 4.0422 0.405187 4.16064 0.246355 4.34276C0.087522 4.52488 1.00136e-05 4.75835 0 5L0.00933266 5.136C0.0421972 5.37541 0.16064 5.59481 0.342758 5.75364C0.524876 5.91248 0.758349 5.99999 0.999999 6H2V7L2.00933 7.136C2.0422 7.37541 2.16064 7.59481 2.34276 7.75364C2.52487 7.91248 2.75835 7.99999 3 8L3.136 7.99067C3.624 7.924 4 7.50667 4 7V6H5L5.136 5.99067C5.624 5.924 6 5.50667 6 5L5.99067 4.864C5.9578 4.62459 5.83936 4.40519 5.65724 4.24636C5.47512 4.08752 5.24165 4.00001 5 4H4V3L3.99067 2.864C3.9578 2.6246 3.83936 2.40519 3.65724 2.24636C3.47512 2.08752 3.24165 2.00001 3 2Z"
                fill="#2F80ED"
              />
              <path
                d="M7 0L6.95467 0.00311109C6.87487 0.0140659 6.80173 0.053547 6.74879 0.114253C6.69584 0.174959 6.66667 0.252783 6.66667 0.333333V0.666667H6.33333L6.288 0.669778C6.2082 0.680733 6.13506 0.720214 6.08212 0.78092C6.02917 0.841626 6 0.91945 6 1L6.00311 1.04533C6.01407 1.12514 6.05355 1.19827 6.11425 1.25121C6.17496 1.30416 6.25278 1.33333 6.33333 1.33333H6.66667V1.66667L6.66978 1.712C6.68073 1.7918 6.72021 1.86494 6.78092 1.91788C6.84162 1.97083 6.91945 2 7 2L7.04533 1.99689C7.208 1.97467 7.33333 1.83556 7.33333 1.66667V1.33333H7.66667L7.712 1.33022C7.87467 1.308 8 1.16889 8 1L7.99689 0.954667C7.98593 0.874865 7.94645 0.80173 7.88575 0.748785C7.82504 0.695841 7.74722 0.66667 7.66667 0.666667H7.33333V0.333333L7.33022 0.288C7.31927 0.208198 7.27979 0.135063 7.21908 0.0821187C7.15837 0.0291745 7.08055 3.39684e-06 7 0Z"
                fill="#2F80ED"
              />
              <path
                d="M8 6.00012L7.90933 6.00634C7.74973 6.02825 7.60346 6.10722 7.49757 6.22863C7.39168 6.35004 7.33334 6.50569 7.33333 6.66679V7.33346H6.66667L6.576 7.33968C6.4164 7.36159 6.27012 7.44055 6.16424 7.56196C6.05835 7.68337 6.00001 7.83902 6 8.00012L6.00622 8.09079C6.02813 8.25039 6.10709 8.39666 6.22851 8.50255C6.34992 8.60844 6.50557 8.66678 6.66667 8.66679H7.33333V9.33346L7.33956 9.42412C7.36147 9.58373 7.44043 9.73 7.56184 9.83588C7.68325 9.94177 7.8389 10.0001 8 10.0001L8.09067 9.9939C8.416 9.94946 8.66667 9.67123 8.66667 9.33346V8.66679H9.33333L9.424 8.66057C9.74933 8.61612 10 8.3379 10 8.00012L9.99378 7.90946C9.97187 7.74985 9.89291 7.60358 9.77149 7.49769C9.65008 7.3918 9.49443 7.33346 9.33333 7.33346H8.66667V6.66679L8.66044 6.57612C8.63853 6.41652 8.55957 6.27025 8.43816 6.16436C8.31675 6.05847 8.1611 6.00013 8 6.00012Z"
                fill="#2F80ED"
              />
            </svg>
          </avatar>
        </woot-thumbnail>
      </div>
    </div>
  </li>
</template>

<script>
import WootButton from '../../../ui/WootButton.vue';
import Avatar from '../../Avatar.vue';
import OpenAPI from 'dashboard/api/integrations/openapi';
import { mapGetters } from 'vuex';
import aiMixin from 'dashboard/mixins/aiMixin';

export default {
  name: 'LabelSuggestion',
  components: {
    Avatar,
    WootButton,
  },
  mixins: [aiMixin],
  props: {
    chatLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      fetchingSuggestions: false,
      suggestedLabels: [],
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({
      allLabels: 'labels/getLabels',
    }),
    preparedLabels() {
      return this.allLabels.filter(label =>
        this.suggestedLabels.includes(label.title)
      );
    },
    shouldShowSuggestions() {
      return (
        !this.fetchingSuggestions &&
        this.preparedLabels.length &&
        this.chatLabels.length === 0
      );
    },
  },
  watch: {
    conversationId() {
      this.selectedLabels = [];
      this.suggestedLabels = [];
      this.fetchIfRequired();
    },
  },
  mounted() {
    this.selectedLabels = [];
    this.suggestedLabels = [];
    this.fetchIfRequired();
  },
  methods: {
    async fetchIfRequired() {
      if (this.chatLabels.length !== 0) {
        return;
      }

      this.fetchIntegrationsIfRequired().then(() => {
        if (this.isAIIntegrationEnabled) {
          this.fetchLabelSuggestion().then(labels => {
            this.suggestedLabels = labels;
          });
        }
      });
    },
    async fetchLabelSuggestion() {
      try {
        this.fetchingSuggestions = true;
        const result = await OpenAPI.processEvent({
          type: 'label_suggestion',
          hookId: this.hookId,
          conversationId: this.conversationId,
        });

        const {
          data: { message: labels },
        } = result;

        return this.cleanLabels(labels);
      } catch (error) {
        return [];
      } finally {
        this.fetchingSuggestions = false;
      }
    },
    cleanLabels(labels) {
      return labels
        .toLowerCase() // Set it to lowercase
        .split(',') // split the string into an array
        .filter(label => label.trim()) // remove any empty strings
        .filter((label, index, self) => self.indexOf(label) === index) // remove any duplicates
        .map(label => label.trim()); // trim the words
    },
    addLabel(label) {
      if (!this.selectedLabels.includes(label)) {
        this.selectedLabels.push(label);
      } else {
        this.selectedLabels = this.selectedLabels.filter(l => l !== label);
      }
    },
    addAllLabels() {
      let labelsToAdd = this.selectedLabels;
      if (!labelsToAdd.length) {
        labelsToAdd = this.preparedLabels.map(label => label.title);
      }
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: labelsToAdd,
      });
    },
  },
};
</script>

<style scoped lang="scss">
.wrap {
  display: flex;
}

.label-suggestion {
  flex-direction: row;
  justify-content: flex-end;
  margin-top: var(--space-normal);

  .label-suggestion--container {
    max-width: 300px;
  }

  .label-suggestion--options {
    text-align: right;
  }

  .label-suggestion--title {
    color: var(--b-600);
    font-size: var(--font-size-micro);
    line-height: var(--font-size-big);
  }
}
</style>
