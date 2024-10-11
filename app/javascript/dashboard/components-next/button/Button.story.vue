<script setup>
import Button from './Button.vue';
</script>

<template>
  <Story title="Components/Button" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-900">
        <Button label="Default Button" />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Disabled" disabled />
        <Button label="Disabled" variant="outline" disabled />
        <Button label="Disabled" disabled icon="delete" variant="outline" />
        <Button
          label="Disabled"
          disabled
          icon="delete"
          variant="destructive"
          size="sm"
        />
        <Button
          label="Disabled"
          disabled
          icon="delete"
          variant="ghost"
          size="sm"
        />
        <Button
          label="Disabled"
          disabled
          icon="delete"
          variant="link"
          size="sm"
        />
      </div>
    </Variant>

    <Variant title="Disabled with icon">
      <div class="p-4 bg-white dark:bg-slate-900">
        <Button label="Disabled Button" icon="emoji-add" disabled />
      </div>
    </Variant>

    <Variant title="Different variant">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Default" variant="default" />
        <Button label="Destructive" variant="destructive" />
        <Button label="Outline" variant="outline" />
        <Button label="Secondary" variant="secondary" />
        <Button label="Ghost" variant="ghost" />
        <Button label="Link" variant="link" />
      </div>
    </Variant>

    <Variant title="Different variant with icon only">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button icon="emoji-add" variant="default" />
        <Button icon="emoji-add" variant="destructive" />
        <Button icon="emoji-add" variant="outline" />
        <Button icon="emoji-add" variant="secondary" />
        <Button icon="emoji-add" variant="ghost" />
        <Button icon="emoji-add" variant="link" />
      </div>
    </Variant>

    <Variant title="Different size">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Default" />
        <Button label="Large" size="lg" />
        <Button label="Small" size="sm" />
      </div>
    </Variant>

    <Variant title="Different text variant">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Default" text-variant="default" variant="outline" />
        <Button label="Success" text-variant="success" variant="outline" />
        <Button label="Warning" text-variant="warning" variant="outline" />
        <Button label="Danger" text-variant="danger" variant="outline" />
        <Button label="Info" text-variant="info" variant="outline" />
      </div>
    </Variant>

    <Variant title="Button with left icon with different sizes and icon only">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Default" icon="emoji-add" icon-position="left" />
        <Button
          label="Default LG"
          icon="emoji-add"
          icon-position="left"
          size="lg"
        />
        <Button
          label="Default SM"
          icon="emoji-add"
          icon-position="left"
          size="sm"
        />
        <Button icon="emoji-add" size="icon" />
      </div>
    </Variant>

    <Variant title="Button with right icon with different sizes and icon only">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Button label="Default" icon="emoji-add" icon-position="right" />
        <Button
          label="Default LG"
          icon="emoji-add"
          icon-position="right"
          size="lg"
        />
        <Button
          label="Default SM"
          icon="emoji-add"
          icon-position="right"
          size="sm"
        />
        <Button icon="emoji-add" size="icon" />
      </div>
    </Variant>
  </Story>
</template>
