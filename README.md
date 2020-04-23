# PrivPage

[![Gitter](https://img.shields.io/badge/chat-on_gitter-red.svg?style=flat-square)](https://gitter.im/Priv-Page/community)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

Serves static sites from a `privpage` branch, using GitHub's OAuth2.

## Usage

Import test environment variables:

`set -a; . ./.env-test; set +a`

Build

`crystal build src/privpage.cr`

Execute

`./privpage`

Test:
- https://priv-page--test.github.privpage.net
- https://priv-page--test-crossload.github.privpage.net

## Architecture

This is a high level explanation of how this project works.

For more information of how GitHub OAuth works, see [the official documentation](https://developer.github.com/apps/building-github-apps/identifying-and-authorizing-users-for-github-apps/).

1. The client requests a resource
- The session cookie is present and valid? Go to `3.`
- Otherwise, redirects to the provider OAuth page

2. Provider (e.g. GitHub) OAuth page
- If successful, redirects to the callback (this service)

4. The callback request is received from the OAuth provider
- Gets an OAuth token, then store it in the service with a `random_key`
- The `random_key` is set in a session cookie

3. A call is performed to the API to get the resource, that is then served to the client.
