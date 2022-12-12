import { Component } from 'react';
import { API } from '@storybook/api';
import { ActionDisplay } from '../../models';
interface ActionLoggerProps {
    active: boolean;
    api: API;
}
interface ActionLoggerState {
    actions: ActionDisplay[];
}
export default class ActionLogger extends Component<ActionLoggerProps, ActionLoggerState> {
    private mounted;
    constructor(props: ActionLoggerProps);
    componentDidMount(): void;
    componentWillUnmount(): void;
    handleStoryChange: () => void;
    addAction: (action: ActionDisplay) => void;
    clearActions: () => void;
    render(): JSX.Element;
}
export {};
