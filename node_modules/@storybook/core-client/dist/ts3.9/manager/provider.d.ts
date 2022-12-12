import { Provider } from '@storybook/ui';
import type { Config, Types } from '@storybook/addons';
export default class ReactProvider extends Provider {
    private addons;
    private channel;
    private serverChannel?;
    constructor();
    getElements(type: Types): import("@storybook/addons").Collection;
    getConfig(): Config;
    handleAPI(api: unknown): void;
}
