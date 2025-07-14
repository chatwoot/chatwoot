import { defineStore } from "@histoire/vendors/pinia";
import { watch } from "@histoire/vendors/vue";
import { useStorage } from "@histoire/vendors/vue-use";
import { useStoryStore } from "./story.js";
"use strict";
const useFolderStore = defineStore("folder", () => {
  const openedFolders = useStorage(
    "_histoire-tree-state",
    /* @__PURE__ */ new Map()
  );
  function getStringPath(path) {
    return path.join("␜");
  }
  function toggleFolder(path, defaultToggleValue = true) {
    const stringPath = getStringPath(path);
    const currentValue = openedFolders.value.get(stringPath);
    if (currentValue == null) {
      setFolderOpen(stringPath, defaultToggleValue);
    } else if (currentValue) {
      setFolderOpen(stringPath, false);
    } else {
      setFolderOpen(stringPath, true);
    }
  }
  function setFolderOpen(path, value) {
    const stringPath = typeof path === "string" ? path : getStringPath(path);
    openedFolders.value.set(stringPath, value);
  }
  function isFolderOpened(path, defaultValue = false) {
    const value = openedFolders.value.get(getStringPath(path));
    if (value == null) {
      return defaultValue;
    }
    return value;
  }
  function openFileFolders(path) {
    for (let pathLength = 1; pathLength < path.length; pathLength++) {
      setFolderOpen(path.slice(0, pathLength), true);
    }
  }
  const storyStore = useStoryStore();
  watch(() => storyStore.currentStory, (story) => {
    if (story) {
      openFileFolders(story.file.path);
    }
  });
  return {
    isFolderOpened,
    toggleFolder
  };
});
export {
  useFolderStore
};
