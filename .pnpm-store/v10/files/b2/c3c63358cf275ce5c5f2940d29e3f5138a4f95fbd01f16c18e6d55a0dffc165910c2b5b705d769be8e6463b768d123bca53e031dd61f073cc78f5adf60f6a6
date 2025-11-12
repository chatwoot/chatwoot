import QUnit from 'qunit';
import { forEachMediaGroup } from '../src/media-groups';

QUnit.module('forEachMediaGroup');

QUnit.test('runs callback for each audio media group', function(assert) {
  const master = {
    mediaGroups: {
      AUDIO: {
        au1: {
          en: { en: 'en' },
          es: { es: 'es' }
        },
        au2: {
          de: { de: 'de' },
          fr: { fr: 'fr' }
        }
      },
      OTHER: {
        other1: {
          other11: { other11: 'other11' },
          other12: { other12: 'other12' }
        },
        other2: {
          other21: { other21: 'other21' },
          other22: { other22: 'other22' }
        }
      }
    }
  };
  const iteratedMediaGroups = [];

  forEachMediaGroup(
    master,
    ['AUDIO'],
    (mediaGroup) => iteratedMediaGroups.push(mediaGroup)
  );

  assert.deepEqual(
    iteratedMediaGroups,
    [
      { en: 'en' },
      { es: 'es' },
      { de: 'de' },
      { fr: 'fr' }
    ],
    'iterated audio media groups'
  );
});

QUnit.test('runs callback for each subtitle media group', function(assert) {
  const master = {
    mediaGroups: {
      SUBTITLES: {
        sub1: {
          en: { en: 'en' },
          es: { es: 'es' }
        },
        sub2: {
          de: { de: 'de' },
          fr: { fr: 'fr' }
        }
      },
      OTHER: {
        other1: {
          other11: { other11: 'other11' },
          other12: { other12: 'other12' }
        },
        other2: {
          other21: { other21: 'other21' },
          other22: { other22: 'other22' }
        }
      }
    }
  };
  const iteratedMediaGroups = [];

  forEachMediaGroup(
    master,
    ['SUBTITLES'],
    (mediaGroup) => iteratedMediaGroups.push(mediaGroup)
  );

  assert.deepEqual(
    iteratedMediaGroups,
    [
      { en: 'en' },
      { es: 'es' },
      { de: 'de' },
      { fr: 'fr' }
    ],
    'iterated subtitles media groups'
  );
});

QUnit.test('runs callback for each audio and subtitles media group', function(assert) {
  const master = {
    mediaGroups: {
      AUDIO: {
        au1: {
          en: { en: 'en' },
          es: { es: 'es' }
        },
        au2: {
          de: { de: 'de' },
          fr: { fr: 'fr' }
        }
      },
      SUBTITLES: {
        sub1: {
          enS: { enS: 'enS' },
          esS: { esS: 'esS' }
        },
        sub2: {
          deS: { deS: 'deS' },
          frS: { frS: 'frS' }
        }
      },
      OTHER: {
        other1: {
          other11: { other11: 'other11' },
          other12: { other12: 'other12' }
        },
        other2: {
          other21: { other21: 'other21' },
          other22: { other22: 'other22' }
        }
      }
    }
  };
  const iteratedMediaGroups = [];

  forEachMediaGroup(
    master,
    ['AUDIO', 'SUBTITLES'],
    (mediaGroup) => iteratedMediaGroups.push(mediaGroup)
  );

  assert.deepEqual(
    iteratedMediaGroups,
    [
      { en: 'en' },
      { es: 'es' },
      { de: 'de' },
      { fr: 'fr' },
      { enS: 'enS' },
      { esS: 'esS' },
      { deS: 'deS' },
      { frS: 'frS' }
    ],
    'iterated audio and subtitles media groups'
  );
});

QUnit.test('does not run callback for non specified media groups', function(assert) {
  const master = {
    mediaGroups: {
      'VIDEO': { v1: { en: { en: 'en' } } },
      'CLOSED-CAPTIONS': { cc1: { en: { en: 'en' } } }
    }
  };
  const iteratedMediaGroups = [];

  forEachMediaGroup(
    master,
    ['AUDIO', 'SUBTITLES'],
    (mediaGroup) => iteratedMediaGroups.push(mediaGroup)
  );

  assert.deepEqual(iteratedMediaGroups, [], 'did not iterate non specified media groups');
});
