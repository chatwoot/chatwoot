const FRAMEWORKS = ['angular', 'ember', 'html', 'marko', 'mithril', 'preact', 'rax', 'react', 'react-native', 'riot', 'svelte', 'vue', 'web-components'];
export const getFrameworks = ({
  dependencies,
  devDependencies
}) => {
  const allDeps = {};
  Object.assign(allDeps, dependencies || {});
  Object.assign(allDeps, devDependencies || {});
  return FRAMEWORKS.filter(f => !!allDeps[`@storybook/${f}`]);
};