import { withBackground } from './decorators/withBackground';
import { withGrid } from './decorators/withGrid';
export const decorators = [withGrid, withBackground];
export const parameters = {
  backgrounds: {
    grid: {
      cellSize: 20,
      opacity: 0.5,
      cellAmount: 5
    },
    values: [{
      name: 'light',
      value: '#F8F8F8'
    }, {
      name: 'dark',
      value: '#333333'
    }]
  }
};