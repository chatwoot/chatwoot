import React from 'react';
import axe from 'axe-core';
import { mountToDoc } from './test-helpers';

import Link from './link';

test('Link has no axe violations', done => {
  const linkComponent = mountToDoc(
    <Link page="http://www.axe-core.org">axe website</Link>
  );
  const linkNode = linkComponent.getDOMNode();

  const config = {
    rules: {
      'color-contrast': { enabled: false },
      'link-in-text-block': { enabled: false }
    }
  };
  axe.run(linkNode, config, (err, { violations }) => {
    expect(err).toBe(null);
    expect(violations).toHaveLength(0);
    done();
  });
});
