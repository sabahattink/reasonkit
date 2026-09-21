'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const fixtureRoot = path.resolve(process.argv[2] || path.join(__dirname, '..', 'fixture-public'));

function loadModules(root) {
  return {
    cache: require(path.join(root, 'src', 'config-cache')),
    loader: require(path.join(root, 'src', 'config-loader')),
    source: require(path.join(root, 'src', 'profile-source'))
  };
}

function workspaceRoot(name) {
  return path.join(fixtureRoot, 'workspaces', name);
}

test('separates file-backed bases for different workspace roots', () => {
  const { cache: cacheModule, loader: loaderModule } = loadModules(fixtureRoot);
  const cache = new cacheModule.ConfigCache();
  const loader = loaderModule.createConfigLoader({ cache });

  const alpha = loader.load({ rootDir: workspaceRoot('alpha'), profile: 'development' });
  const beta = loader.load({ rootDir: workspaceRoot('beta'), profile: 'development' });

  assert.equal(alpha.serviceName, 'alpha-api');
  assert.equal(beta.serviceName, 'beta-api');
  assert.equal(beta.region, 'us-east');
  assert.equal(beta.port, 7202);
  assert.equal(cache.size(), 2);
});

test('normalizes equivalent workspace roots while retaining per-call overlays', () => {
  const { cache: cacheModule, loader: loaderModule, source: sourceModule } = loadModules(fixtureRoot);
  const cache = new cacheModule.ConfigCache();
  let reads = 0;
  const loader = loaderModule.createConfigLoader({
    cache,
    readProfileFn: (...args) => {
      reads += 1;
      return sourceModule.readProfile(...args);
    }
  });

  const canonicalRoot = path.resolve(workspaceRoot('gamma'));
  const equivalentRoot = `${canonicalRoot}${path.sep}nested${path.sep}..`;
  const first = loader.load({
    rootDir: canonicalRoot,
    profile: 'development',
    env: { APP_REGION: 'first-region' }
  });
  const second = loader.load({
    rootDir: equivalentRoot,
    profile: 'development',
    env: { APP_REGION: 'second-region' },
    overrides: { timeoutMs: 9876 }
  });

  assert.equal(first.serviceName, 'gamma-worker');
  assert.equal(second.serviceName, 'gamma-worker');
  assert.equal(second.region, 'second-region');
  assert.equal(second.timeoutMs, 9876);
  assert.equal(reads, 1);
  assert.equal(cache.size(), 1);
});
