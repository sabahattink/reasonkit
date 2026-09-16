const assert = require('node:assert/strict');
const { parseEnv } = require('./parser');

const input = [
  '# comment',
  ' API_URL = "https://example.test/v1?a=1" ',
  'export RETRIES=3',
  'NAME=ReasonKit',
  'MALFORMED',
  ''
].join('\n');

const expected = [
  { key: 'API_URL', value: 'https://example.test/v1?a=1' },
  { key: 'RETRIES', value: '3' },
  { key: 'NAME', value: 'ReasonKit' }
];

assert.deepStrictEqual(parseEnv(input), expected);
console.log('TASK-001 fixture passes');
