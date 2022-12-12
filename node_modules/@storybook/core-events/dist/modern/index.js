var events; // Enables: `import Events from ...`

(function (events) {
  events["CHANNEL_CREATED"] = "channelCreated";
  events["CONFIG_ERROR"] = "configError";
  events["STORY_INDEX_INVALIDATED"] = "storyIndexInvalidated";
  events["STORY_SPECIFIED"] = "storySpecified";
  events["SET_STORIES"] = "setStories";
  events["SET_CURRENT_STORY"] = "setCurrentStory";
  events["CURRENT_STORY_WAS_SET"] = "currentStoryWasSet";
  events["FORCE_RE_RENDER"] = "forceReRender";
  events["FORCE_REMOUNT"] = "forceRemount";
  events["PRELOAD_STORIES"] = "preloadStories";
  events["STORY_PREPARED"] = "storyPrepared";
  events["STORY_CHANGED"] = "storyChanged";
  events["STORY_UNCHANGED"] = "storyUnchanged";
  events["STORY_RENDERED"] = "storyRendered";
  events["STORY_MISSING"] = "storyMissing";
  events["STORY_ERRORED"] = "storyErrored";
  events["STORY_THREW_EXCEPTION"] = "storyThrewException";
  events["STORY_RENDER_PHASE_CHANGED"] = "storyRenderPhaseChanged";
  events["UPDATE_STORY_ARGS"] = "updateStoryArgs";
  events["STORY_ARGS_UPDATED"] = "storyArgsUpdated";
  events["RESET_STORY_ARGS"] = "resetStoryArgs";
  events["SET_GLOBALS"] = "setGlobals";
  events["UPDATE_GLOBALS"] = "updateGlobals";
  events["GLOBALS_UPDATED"] = "globalsUpdated";
  events["REGISTER_SUBSCRIPTION"] = "registerSubscription";
  events["PREVIEW_KEYDOWN"] = "previewKeydown";
  events["SELECT_STORY"] = "selectStory";
  events["STORIES_COLLAPSE_ALL"] = "storiesCollapseAll";
  events["STORIES_EXPAND_ALL"] = "storiesExpandAll";
  events["DOCS_RENDERED"] = "docsRendered";
  events["SHARED_STATE_CHANGED"] = "sharedStateChanged";
  events["SHARED_STATE_SET"] = "sharedStateSet";
  events["NAVIGATE_URL"] = "navigateUrl";
  events["UPDATE_QUERY_PARAMS"] = "updateQueryParams";
})(events || (events = {}));

export default events; // Enables: `import * as Events from ...` or `import { CHANNEL_CREATED } as Events from ...`
// This is the preferred method

export const {
  CHANNEL_CREATED,
  CONFIG_ERROR,
  STORY_INDEX_INVALIDATED,
  STORY_SPECIFIED,
  SET_STORIES,
  SET_CURRENT_STORY,
  CURRENT_STORY_WAS_SET,
  FORCE_RE_RENDER,
  FORCE_REMOUNT,
  STORY_PREPARED,
  STORY_CHANGED,
  STORY_UNCHANGED,
  PRELOAD_STORIES,
  STORY_RENDERED,
  STORY_MISSING,
  STORY_ERRORED,
  STORY_THREW_EXCEPTION,
  STORY_RENDER_PHASE_CHANGED,
  UPDATE_STORY_ARGS,
  STORY_ARGS_UPDATED,
  RESET_STORY_ARGS,
  SET_GLOBALS,
  UPDATE_GLOBALS,
  GLOBALS_UPDATED,
  REGISTER_SUBSCRIPTION,
  PREVIEW_KEYDOWN,
  SELECT_STORY,
  STORIES_COLLAPSE_ALL,
  STORIES_EXPAND_ALL,
  DOCS_RENDERED,
  SHARED_STATE_CHANGED,
  SHARED_STATE_SET,
  NAVIGATE_URL,
  UPDATE_QUERY_PARAMS
} = events; // Used to break out of the current render without showing a redbox

export const IGNORED_EXCEPTION = new Error('ignoredException');