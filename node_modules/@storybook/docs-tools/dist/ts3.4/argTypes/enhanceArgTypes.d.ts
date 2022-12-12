import { AnyFramework, StoryContextForEnhancers } from '@storybook/csf';
export declare const enhanceArgTypes: <TFramework extends AnyFramework>(context: StoryContextForEnhancers<TFramework, import("@storybook/csf").Args>) => import("@storybook/csf").StrictArgTypes<import("@storybook/csf").Args> | import("@storybook/addons").Parameters;
