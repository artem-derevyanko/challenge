/** @type {import('next').NextConfig} */

const { HASURA_CONSOLE_HOST, HASURA_HOST, API_MODE } = process.env;

module.exports = {
  reactStrictMode: true,
  publicRuntimeConfig: {
    HASURA_HOST: API_MODE !== 'production' ? HASURA_CONSOLE_HOST : HASURA_HOST,
  },
  serverRuntimeConfig: {
    HASURA_HOST: HASURA_HOST,
  },
};
