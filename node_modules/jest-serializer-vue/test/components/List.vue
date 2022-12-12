<template>
    <ul>
        <li
            v-for="(item, key) in items"
            :key="key">
            {{ item }}
        </li>
    </ul>
</template>

<script>
export default {
  name: 'list',
  props: [
    'items'
  ]
}
</script>
