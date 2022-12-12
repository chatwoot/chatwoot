<template>
    <div>
        <h1>parent</h1>
        <main>
          <child />
          <child />
          <child />
        </main>
    </div>
</template>

<script>
import Child from './Child.vue'

export default {
  name: 'parent',
  components: {
    Child
  }
}
</script>
