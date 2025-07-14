import { router } from "../router.js";
import { useStoryStore } from "../stores/story.js";
import { openInEditor } from "./open-in-editor.js";
"use strict";
const builtinCommands = [
  {
    id: "builtin:open-in-editor",
    label: "Open file in editor",
    icon: "carbon:script-reference",
    showIf: ({ route }) => route.name === "story" && !!useStoryStore().currentStory,
    getParams: () => {
      var _a, _b, _c;
      const story = useStoryStore().currentStory;
      let file;
      if (story.docsOnly) {
        file = ((_a = story.file) == null ? void 0 : _a.docsFilePath) ?? ((_b = story.file) == null ? void 0 : _b.filePath);
      } else {
        file = (_c = story.file) == null ? void 0 : _c.filePath;
      }
      return {
        file
      };
    },
    clientAction: ({ file }) => {
      openInEditor(file);
    }
  },
  {
    id: "builtin:histoire-docs",
    label: "Open Histoire Documentation",
    icon: "carbon:help",
    clientAction: () => {
      window.open("https://histoire.dev/guide/getting-started.html", "_blank");
    }
  }
];
function executeCommand(command, params) {
  var _a;
  if (import.meta.hot) {
    import.meta.hot.send("histoire:dev-command", {
      id: command.id,
      params
    });
    (_a = command.clientAction) == null ? void 0 : _a.call(command, params, getCommandContext());
  }
}
function getCommandContext() {
  const storyStore = useStoryStore();
  return {
    route: router.currentRoute.value,
    currentStory: storyStore.currentStory,
    currentVariant: storyStore.currentVariant
  };
}
export {
  builtinCommands,
  executeCommand,
  getCommandContext
};
