function parseEnv(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => {
      const [key, value] = line.split('=');
      return {
        key: key.trim().replace(/^export\s+/, ''),
        value: value.trim().replace(/^["']|["']$/g, '')
      };
    });
}

module.exports = { parseEnv };
