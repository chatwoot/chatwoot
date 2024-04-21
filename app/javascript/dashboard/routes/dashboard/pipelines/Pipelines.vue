<template>
  <div id="app">
    <drag-drop
      :dropzones="dropGroups"
      :dropzones-title="'XYZ Company Teams'"
      :original-data="stories"
      :original-title="'Tasks to be distributed'"
      :in-place="true"
      :enable-save="false"
      :enable-cancel="false"
      @dropInOriginalBucket="originalBucketDropEvent"
      @dropInDestinationBucket="destinationBucketDropEvent"
    >
      <template #dd-card="{ cardData }">
        <custom-card :data="cardData" @done="doneMarked" />
      </template>
    </drag-drop>
  </div>
</template>

<script>
import DragDrop from 'vue-drag-n-drop';
import CustomCard from './CustomCard.vue';

export default {
  components: {
    DragDrop,
    CustomCard,
  },
  data() {
    return {
      stories: [
        {
          title: 'Strategy 101',
          description: 'Create a draft of business plan',
          time: '3 days',
          done: false,
        },
        {
          title: 'Strategy 102',
          description: 'Finalize the plan',
          time: '4 days',
          done: false,
        },
        {
          title: 'Tech diagram',
          description: 'Draw the tech data',
          time: '4 days',
          done: false,
        },
        {
          title: 'Place Holder',
          description: 'Data Science Team',
          time: '5 days',
          done: false,
        },
        {
          title: 'Strategy 104',
          description: 'Create a draft of business plan',
          time: '3 days',
          done: false,
        },
        {
          title: 'Strategy 105',
          description: 'Finalize the plan',
          time: '4 days',
          done: false,
        },
        {
          title: 'Tech diagram 1',
          description: 'Draw the tech data',
          time: '4 days',
          done: false,
        },
        {
          title: 'Place Holder 2',
          description: 'Data Science Team',
          time: '5 days',
          done: false,
        },
      ],

      dropGroups: [
        {
          name: 'Business Team',
          children: [],
        },
        {
          name: 'Tech Dept',
          children: [],
        },
        {
          name: 'Marketing Dept',
          children: [],
        },
        {
          name: 'CS Team',
          children: [],
        },
        {
          name: 'Support Dept',
          children: [],
        },
        {
          name: 'Finance Dept',
          children: [],
        },
      ],
    };
  },

  methods: {
    save(received) {
      console.log('Received:', received);
    },

    doneMarked(data) {
      data.done = true;
      alert(data.title);
    },

    originalBucketDropEvent(result) {
      console.log('Original: ', result);
    },

    destinationBucketDropEvent(columnName, result) {
      console.log('Destination: ', columnName, result);
    },

    cancel() {
      console.log('Cancel hit');
    },
  },
};
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}
</style>
