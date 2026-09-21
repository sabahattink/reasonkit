'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');
const { ConfigCache } = require('../src/config-cache');
const { createConfigLoader } = require('../src/config-loader');
const { readProfile } = require('../src/profile-source');

const workspaceRoot = (name) => path.join(__dirname, '..', 'workspaces', name);

test('loads file values and applies numeric environment and request overrides', () => {
  const loader = createConfigLoader();

  const config = loader.load({
    rootDir: workspaceRoot('alpha'),
    env: { APP_PORT: '7410' },
    overrides: { timeoutMs: 4200 }
  });

  assert.equal(config.serviceName, 'alpha-api');
  assert.equal(config.region, 'eu-central');
  assert.equal(config.port, 7410);
  assert.equal(config.timeoutMs, 4200);
});

test('does not reuse one workspace profile for another workspace', () => {
  const cache = new ConfigCache();
  const loader = createConfigLoader({ cache });

  const alpha = loader.load({ rootDir: workspaceRoot('alpha') });
  const beta = loader.load({ rootDir: workspaceRoot('beta') });

  assert.equal(alpha.serviceName, 'alpha-api');
  assert.equal(beta.serviceName, 'beta-api');
  assert.equal(beta.region, 'us-east');
  assert.equal(beta.port, 7202);
  assert.equal(cache.size(), 2);
});

test('reuses the base while evaluating per-call environment overlays', () => {
  const cache = new ConfigCache();
  let reads = 0;
  const loader = createConfigLoader({
    cache,
    readProfileFn: (...args) => {
      reads += 1;
      return readProfile(...args);
    }
  });

  const first = loader.load({
    rootDir: workspaceRoot('gamma'),
    env: { APP_REGION: 'first-region' }
  });
  const second = loader.load({
    rootDir: workspaceRoot('gamma'),
    env: { APP_REGION: 'second-region' },
    overrides: { timeoutMs: 9999 }
  });

  assert.equal(first.region, 'first-region');
  assert.equal(second.region, 'second-region');
  assert.equal(second.timeoutMs, 9999);
  assert.equal(reads, 1);
  assert.equal(cache.size(), 1);
});
