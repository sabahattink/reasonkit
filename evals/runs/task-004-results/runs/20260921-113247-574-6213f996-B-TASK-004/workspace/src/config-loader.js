'use strict';

const path = require('node:path');
const { DEFAULT_CONFIG } = require('./default-config');
const { ConfigCache } = require('./config-cache');
const { parseEnv } = require('./env-overrides');
const { readProfile } = require('./profile-source');

function createConfigLoader({ cache = new ConfigCache(), readProfileFn = readProfile } = {}) {
  function load({ rootDir, profile = 'development', env = {}, overrides = {} } = {}) {
    if (!rootDir) {
      throw new Error('rootDir is required');
    }

    const cacheKey = `${path.resolve(rootDir)}\0${profile}`;
    let base = cache.get(cacheKey);

    if (base === undefined) {
      const fileConfig = readProfileFn(rootDir, profile);
      base = { ...DEFAULT_CONFIG, ...fileConfig };
      cache.set(cacheKey, base);
    }

    return {
      ...base,
      ...parseEnv(env),
      ...overrides
    };
  }

  return { load, cache };
}

module.exports = { createConfigLoader };
