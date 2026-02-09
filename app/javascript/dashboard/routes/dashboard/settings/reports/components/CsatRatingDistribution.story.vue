<script setup>
import CsatRatingDistribution from './CsatRatingDistribution.vue';

const sampleRatingPercentage = {
  1: 5,
  2: 10,
  3: 15,
  4: 25,
  5: 45,
};

const sampleRatingCount = {
  1: 50,
  2: 100,
  3: 150,
  4: 250,
  5: 450,
};

const emptyRatingPercentage = {
  1: 0,
  2: 0,
  3: 0,
  4: 0,
  5: 0,
};

const emptyRatingCount = {
  1: 0,
  2: 0,
  3: 0,
  4: 0,
  5: 0,
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/Reports/CsatRatingDistribution"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="With Data">
      <div class="p-4 bg-n-background">
        <CsatRatingDistribution
          :rating-percentage="sampleRatingPercentage"
          :rating-count="sampleRatingCount"
          :total-response-count="1000"
        />
      </div>
    </Variant>

    <Variant title="Empty State">
      <div class="p-4 bg-n-background">
        <CsatRatingDistribution
          :rating-percentage="emptyRatingPercentage"
          :rating-count="emptyRatingCount"
          :total-response-count="0"
        />
      </div>
    </Variant>

    <Variant title="Loading State">
      <div class="p-4 bg-n-background">
        <CsatRatingDistribution
          :rating-percentage="emptyRatingPercentage"
          :rating-count="emptyRatingCount"
          :total-response-count="0"
          is-loading
        />
      </div>
    </Variant>
  </Story>
</template>
