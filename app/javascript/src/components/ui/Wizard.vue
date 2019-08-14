
<template>
    <transition-group name="wizard-items" tag="div" class="wizard-box flex-child-shrink" :class="classObject">
      <div class="item" v-for="item in items" v-bind:key="item" :class="{ active: isActive(item), over: isOver(item)  }">
        <h3>{{item.title}}
          <span class="completed" v-if="isOver(item)">
            <i class="ion-checkmark"></i>
          </span>
        </h3>
        <span class="step">
          {{items.indexOf(item)+1}}
        </span>
        <p>{{item.body}}</p>
      </div>
    </transition-group>
</template>

<script>
/* eslint no-console: 0 */
export default {
  props: {
    items: Array,
    isFullwidth: Boolean,
  },

  computed: {
    classObject() {
      return 'full-width';
    },
    activeIndex() {
      return this.items.findIndex(i => i.route === this.$route.name);
    },
  },
  methods: {
    isActive(item) {
      return this.items.indexOf(item) === this.activeIndex;
    },
    isOver(item) {
      return this.items.indexOf(item) < this.activeIndex;
    },
  },
};
</script>
