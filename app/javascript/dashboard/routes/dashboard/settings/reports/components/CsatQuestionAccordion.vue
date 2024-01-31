<template>
  <div class="-mt-px text-sm">
    <button
      class="flex items-center select-none w-full bg-slate-50 dark:bg-slate-800 border border-l-0 border-r-0 border-solid m-0 border-slate-100 dark:border-slate-700/50 cursor-grab justify-between px-4 drag-handle"
      @click="toggleAccordion"
    >
      <div class="flex justify-between mb-0.5">
        <div class="flex justify-end w-4 mr-5">
          <fluent-icon v-if="isOpen" size="35" icon="chevron-down" />
          <fluent-icon v-else size="35" icon="chevron-right" type="solid" />
        </div>
        <h5
          class="text-slate-800 text-sm dark:text-slate-100 mb-0 py-0 pr-2 pl-0"
        >
          {{ question.content }}
        </h5>
      </div>
      <div />
      <div>
        <div class="w-[100%] report-card rtl:[direction:initial] p-2">
          <h3 class="heading text-slate-800 dark:text-slate-100">
            <div class="flex justify-end flex-row-reverse">
              <div
                v-for="(rating, key, index) in ratingPercentage()"
                :key="rating + key + index"
                class="pl-4"
              >
                <span class="my-0 mx-0.5">{{ ratingToEmoji(key) }}</span>
                <span>{{ formatToPercent(rating) }}</span>
              </div>
            </div>
          </h3>
          <div class="mt-2">
            <woot-horizontal-bar :collection="chartData" :height="24" />
          </div>
        </div>
      </div>
    </button>
    <div v-if="isOpen" class="bg-white dark:bg-slate-900">
      <slot />
    </div>
  </div>
</template>

<script>
import { CSAT_RATINGS } from 'shared/constants/messages';
export default {
  components: {},
  props: {
    question: {
      type: Object,
      default: () => {},
    },

    responses: {
      type: Array,
      default: () => [],
    },

    compact: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isOpen: false,
    };
  },
  computed: {
    chartData() {
      const sortedRatings = [...CSAT_RATINGS].sort((a, b) => b.value - a.value);
      return {
        labels: ['Rating'],
        datasets: sortedRatings.map(rating => ({
          label: rating.emoji,
          data: [this.ratingPercentage()[rating.value]],
          backgroundColor: rating.color,
        })),
      };
    },
  },
  methods: {
    toggleAccordion() {
      this.isOpen = !this.isOpen;
    },
    ratingPercentage() {
      return {
        1: this.getRating(1),
        2: this.getRating(2),
        3: this.getRating(3),
        4: this.getRating(4),
        5: this.getRating(5),
      };
    },
    getRating(rating) {
      const fitered = this.responses.filter(
        response => rating === response.rating
      );
      
      if (!fitered.length){
        return "0";
      }

      return ((fitered.length / this.responses.length) * 100).toFixed(2);
    },
    formatToPercent(value) {
      return value ? `${value}%` : '--';
    },
    ratingToEmoji(value) {
      return CSAT_RATINGS.find(rating => rating.value === Number(value)).emoji;
    },
  },
};
</script>
