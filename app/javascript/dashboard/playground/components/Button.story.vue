<script setup>
import Button from './Button.vue';
</script>

<template>
  <Story title="Button" :layout="{ type: 'grid', width: '200px' }">
    <Variant title="Default">
      <Button label="Default Button" variant="default" size="sm" />
    </Variant>

    <Variant title="Destructive">
      <Button label="Destructive" variant="destructive" size="sm" />
    </Variant>

    <Variant title="Outline">
      <Button label="Outline" variant="outline" />
    </Variant>

    <Variant title="Secondary">
      <Button label="Secondary" variant="secondary" />
    </Variant>

    <Variant title="Ghost">
      <Button label="Ghost" variant="ghost" />
    </Variant>

    <Variant title="Link">
      <Button label="Link" variant="link" />
    </Variant>

    <Variant title="With Icon (Left)">
      <Button label="With Icon" icon="more-horizontal" />
    </Variant>

    <Variant title="With Icon (Right)">
      <Button label="With Icon" icon="more-vertical" icon-position="right" />
    </Variant>

    <Variant title="Icon Only">
      <Button icon="ic_fluent_add_24_regular" size="icon" />
    </Variant>

    <Variant title="Small Size">
      <Button label="Small Button" size="sm" />
    </Variant>

    <Variant title="Large Size">
      <Button label="Large Button" size="lg" />
    </Variant>

    <Variant title="Disabled">
      <Button label="Disabled Button" disabled />
    </Variant>

    <Variant title="Click Event">
      <Button label="Click Me" @click="() => alert('Button clicked!')" />
    </Variant>
  </Story>
</template>
