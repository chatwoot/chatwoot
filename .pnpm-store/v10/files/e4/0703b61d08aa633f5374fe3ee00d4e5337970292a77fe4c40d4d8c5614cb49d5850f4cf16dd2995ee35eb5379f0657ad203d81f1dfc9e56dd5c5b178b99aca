import { defineStore } from "@histoire/vendors/pinia";
import { ref } from "@histoire/vendors/vue";
import { getCommandContext, executeCommand } from "../util/commands.js";
"use strict";
const useCommandStore = defineStore("command", () => {
  const selectedCommand = ref(null);
  const showPromptsModal = ref(false);
  function activateCommand(command) {
    var _a, _b;
    selectedCommand.value = command;
    if ((_a = command.prompts) == null ? void 0 : _a.length) {
      showPromptsModal.value = true;
    } else {
      const params = ((_b = command.getParams) == null ? void 0 : _b.call(command, getCommandContext())) ?? {};
      executeCommand(command, params);
    }
  }
  return {
    selectedCommand,
    showPromptsModal,
    activateCommand
  };
});
export {
  useCommandStore
};
