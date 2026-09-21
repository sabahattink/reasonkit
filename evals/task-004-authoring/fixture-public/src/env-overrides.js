'use strict';

function parsePositiveInteger(name, value) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return parsed;
}

function parseEnv(env) {
  const overrides = {};

  if (env.APP_SERVICE_NAME !== undefined) {
    overrides.serviceName = String(env.APP_SERVICE_NAME);
  }
  if (env.APP_REGION !== undefined) {
    overrides.region = String(env.APP_REGION);
  }
  if (env.APP_PORT !== undefined) {
    overrides.port = parsePositiveInteger('APP_PORT', env.APP_PORT);
  }
  if (env.APP_TIMEOUT_MS !== undefined) {
    overrides.timeoutMs = parsePositiveInteger('APP_TIMEOUT_MS', env.APP_TIMEOUT_MS);
  }

  return overrides;
}

module.exports = { parseEnv };
