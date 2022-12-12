import React, { Component } from 'react';
import deepEqual from 'fast-deep-equal';
import { STORY_CHANGED } from '@storybook/core-events';
import { ActionLogger as ActionLoggerComponent } from '../../components/ActionLogger';
import { EVENT_ID } from '../..';

const safeDeepEqual = (a, b) => {
  try {
    return deepEqual(a, b);
  } catch (e) {
    return false;
  }
};

export default class ActionLogger extends Component {
  constructor(props) {
    super(props);
    this.mounted = void 0;

    this.handleStoryChange = () => {
      const {
        actions
      } = this.state;

      if (actions.length > 0 && actions[0].options.clearOnStoryChange) {
        this.clearActions();
      }
    };

    this.addAction = action => {
      this.setState(prevState => {
        const actions = [...prevState.actions];
        const previous = actions.length && actions[0];

        if (previous && safeDeepEqual(previous.data, action.data)) {
          previous.count++; // eslint-disable-line
        } else {
          action.count = 1; // eslint-disable-line

          actions.unshift(action);
        }

        return {
          actions: actions.slice(0, action.options.limit)
        };
      });
    };

    this.clearActions = () => {
      this.setState({
        actions: []
      });
    };

    this.state = {
      actions: []
    };
  }

  componentDidMount() {
    this.mounted = true;
    const {
      api
    } = this.props;
    api.on(EVENT_ID, this.addAction);
    api.on(STORY_CHANGED, this.handleStoryChange);
  }

  componentWillUnmount() {
    this.mounted = false;
    const {
      api
    } = this.props;
    api.off(STORY_CHANGED, this.handleStoryChange);
    api.off(EVENT_ID, this.addAction);
  }

  render() {
    const {
      actions = []
    } = this.state;
    const {
      active
    } = this.props;
    const props = {
      actions,
      onClear: this.clearActions
    };
    return active ? /*#__PURE__*/React.createElement(ActionLoggerComponent, props) : null;
  }

}