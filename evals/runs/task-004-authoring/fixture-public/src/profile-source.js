'use strict';

const fs = require('node:fs');
const path = require('node:path');

function readProfile(rootDir, profile) {
  const profilePath = path.join(rootDir, 'config', `${profile}.json`);
  return JSON.parse(fs.readFileSync(profilePath, 'utf8'));
}

module.exports = { readProfile };
