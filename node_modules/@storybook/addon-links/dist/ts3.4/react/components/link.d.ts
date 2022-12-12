import { PureComponent, ReactNode } from 'react';
interface Props {
    kind: string;
    story: string;
    children: ReactNode;
}
interface State {
    href: string;
}
export default class LinkTo extends PureComponent<Props, State> {
    static defaultProps: Props;
    state: State;
    componentDidMount(): void;
    componentDidUpdate(prevProps: Props): void;
    updateHref: () => Promise<void>;
    handleClick: () => void;
    render(): JSX.Element;
}
export {};
