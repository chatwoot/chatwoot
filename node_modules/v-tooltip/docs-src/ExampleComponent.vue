<template>
  <div class="example-component">
    <span>&lt;I'm a component!</span>
    <br>
    <button v-if="count < 14" class="button" @click="count < 14 && count++">+</button>
    <button v-if="count > 0" class="button" @click="count > 0 && count--">-</button>
    <br>
    <transition-group tag="span" class="counter">
			<span v-for="n in count" :key="n" class="char">{{ char }}</span>
		</transition-group>
		<span>/&gt;</span>
  </div>
</template>

<script>
export default {
  props: {
    char: {
      type: String,
      default: '#',
    },
  },

  data () {
    return {
      count: 0,
    }
  },
}
</script>

<style lang="scss" scoped>
.example-component {
	background: $primary-color;
	padding: 4px 16px;
	border-radius: 3px;
	color: white;
	text-align: center;
	font-family: monospace;
	font-size: 1.2em;
}

.button {
	padding: 2px 6px;
}

.counter {
	font-weight: bold;
}

.char {
  display: inline-block;
  width: 32px;
  text-align: center;
  margin-top: 6px;
  overflow: hidden;

  &.v-enter-active,
  &.v-leave-active {
    transition: width .5s;
  }

  &.v-enter,
  &.v-leave-to {
    width: 0;
  }
}
</style>
