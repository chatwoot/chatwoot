import "core-js/modules/es.array.reduce.js";
import { useState, useEffect } from 'react';
export function useStory(storyId, context) {
  const stories = useStories([storyId], context);
  return stories && stories[0];
}
export function useStories(storyIds, context) {
  const initialStoriesById = context.componentStories().reduce((acc, story) => {
    acc[story.id] = story;
    return acc;
  }, {});
  const [storiesById, setStories] = useState(initialStoriesById);
  useEffect(() => {
    Promise.all(storyIds.map(async storyId => {
      // loadStory will be called every single time useStory is called
      // because useEffect does not use storyIds as an input. This is because
      // HMR can change the story even when the storyId hasn't changed. However, it
      // will be a no-op once the story has loaded. Furthermore, the `story` will
      // have an exact equality when the story hasn't changed, so it won't trigger
      // any unnecessary re-renders
      const story = await context.loadStory(storyId);
      setStories(current => current[storyId] === story ? current : Object.assign({}, current, {
        [storyId]: story
      }));
    }));
  });
  return storyIds.map(storyId => storiesById[storyId]);
}