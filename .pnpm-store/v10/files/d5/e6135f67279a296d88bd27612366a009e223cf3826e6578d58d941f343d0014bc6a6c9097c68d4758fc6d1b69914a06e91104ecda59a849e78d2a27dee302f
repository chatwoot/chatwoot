import { wrapInList } from "prosemirror-schema-list";
import { toggleMark } from "prosemirror-commands";
import { MenuItem } from "prosemirror-menu";
import { undo, redo } from "prosemirror-history";
import { openPrompt } from "../prompt";
import { TextField } from "../TextField";
import {
  blockTypeIsActive,
  cmdItem,
  markItem,
  toggleBlockType,
} from "./common";
import icons from "../icons";
import { markActive } from "../utils";

const wrapListItem = (nodeType, options) =>
  cmdItem(wrapInList(nodeType, options.attrs), options);

const imageUploadItem = (nodeType, onImageUpload) =>
  new MenuItem({
    title: "Upload image",
    icon: icons.image,
    enable() {
      return true;
    },
    run() {
      onImageUpload();
      return true;
    },
  });

const headerItem = (nodeType, options) => {
  const { level = 1 } = options;
  return new MenuItem({
    title: `Heading ${level}`,
    icon: options.icon,
    active(state) {
      return blockTypeIsActive(state, nodeType, { level });
    },
    enable() {
      return true;
    },
    run(state, dispatch, view) {
      if (blockTypeIsActive(state, nodeType, { level })) {
        toggleBlockType(nodeType, { level })(state, dispatch);
        return true;
      }

      toggleBlockType(nodeType, { level })(view.state, view.dispatch);
      view.focus();

      return false;
    },
  });
};

const linkItem = (markType) =>
  new MenuItem({
    title: "Add or remove link",
    icon: icons.link,
    active(state) {
      return markActive(state, markType);
    },
    enable(state) {
      return !state.selection.empty;
    },
    run(state, dispatch, view) {
      if (markActive(state, markType)) {
        toggleMark(markType)(state, dispatch);
        return true;
      }
      openPrompt({
        title: "Create a link",
        fields: {
          href: new TextField({
            label: "https://example.com",
            class: "small",
            required: true,
          }),
        },
        callback(attrs) {
          toggleMark(markType, attrs)(view.state, view.dispatch);
          view.focus();
        },
      });
      return false;
    },
  });

const buildMenuOptions = (
  schema,
  {
    enabledMenuOptions = [
      "strong",
      "em",
      "code",
      "link",
      "undo",
      "redo",
      "bulletList",
      "orderedList",
    ],
    onImageUpload = () => {},
  }
) => {
  const availableMenuOptions = {
    strong: markItem(schema.marks.strong, {
      title: "Toggle strong style",
      icon: icons.strong,
    }),
    em: markItem(schema.marks.em, {
      title: "Toggle emphasis",
      icon: icons.em,
    }),
    code: markItem(schema.marks.code, {
      title: "Toggle code font",
      icon: icons.code,
    }),
    link: linkItem(schema.marks.link),
    bulletList: wrapListItem(schema.nodes.bullet_list, {
      title: "Wrap in bullet list",
      icon: icons.bulletList,
    }),
    orderedList: wrapListItem(schema.nodes.ordered_list, {
      title: "Wrap in ordered list",
      icon: icons.orderedList,
    }),
    undo: new MenuItem({
      title: "Undo last change",
      run: undo,
      enable: (state) => undo(state),
      icon: icons.undo,
    }),
    redo: new MenuItem({
      title: "Redo last undone change",
      run: redo,
      enable: (state) => redo(state),
      icon: icons.redo,
    }),
    h1: headerItem(schema.nodes.heading, {
      level: 1,
      title: "Toggle code font",
      icon: icons.h1,
    }),
    h2: headerItem(schema.nodes.heading, {
      level: 2,
      title: "Toggle code font",
      icon: icons.h2,
    }),
    h3: headerItem(schema.nodes.heading, {
      level: 3,
      title: "Toggle code font",
      icon: icons.h3,
    }),
    imageUpload: imageUploadItem(schema.nodes.image, onImageUpload),
  };

  return [
    enabledMenuOptions
      .filter((menuOptionKey) => !!availableMenuOptions[menuOptionKey])
      .map((menuOptionKey) => availableMenuOptions[menuOptionKey]),
  ];
};

export default buildMenuOptions;
