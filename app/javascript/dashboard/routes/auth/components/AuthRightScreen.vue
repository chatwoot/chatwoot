<template>
  <div class="image--wrap flex-divided-view">
    <img src="../../login.png" alt="Signup" />
  </div>
</template>

<script>
export default {};
</script>

<style lang="scss" scoped>
.image--wrap {
  flex-direction: column;

  img {
    height: 100vh;
    width: 100vw;
  }
}

@media screen and (max-width: 1200px) {
  .image--wrap {
    display: none;
  }
}
</style>
