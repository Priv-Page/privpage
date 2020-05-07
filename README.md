# PrivPage

[![Gitter](https://img.shields.io/badge/chat-on_gitter-red.svg?style=flat-square)](https://gitter.im/Priv-Page/community)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

Serves static sites from a `privpage` branch, using GitHub's OAuth2.

The server is written in [Crystal](https://crystal-lang.org/)

## Environment variables

| variable             | value       |
|----------------------|-------------|
|GITHUB_OAUTH_SECRET_ID|**mandatory**|
|GITHUB_OAUTH_CLIENT_ID|**mandatory**|
|PORT                  | 3000        |

## Usage

First, set the environment variables.

For the test ones: `set -a; . ./.env-test; set +a`

Build (add `--release` for release builds)

`crystal build src/privpage.cr`

Execute

`./privpage`

Test:
- https://priv-page--test.github.privpage.net
- https://priv-page--test-crossload.github.privpage.net
- https://priv-page--test-public.github.privpage.net

## Architecture

This is a high level explanation of how this project works.

For more information of how GitHub OAuth works, see [the official documentation](https://developer.github.com/apps/building-github-apps/identifying-and-authorizing-users-for-github-apps/).

1. The client requests a resource
- If the session cookie is present and valid, go to `3.`
- Otherwise, redirects to the provider's OAuth page

2. Provider's (e.g. GitHub) OAuth page
- If successful, redirects to the callback URL (this service)

4. The callback request is received from the OAuth provider
- Get an OAuth token, then store it server-side with a `random_key`
- The `random_key` is set in a session cookie for the client

5. A call is performed to the API to get the resource, which is then served to the client.
