# PrivPage

[![Gitter](https://img.shields.io/badge/chat-on_gitter-red.svg?style=flat-square)](https://gitter.im/Priv-Page/community)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

Serves static sites from a `privpage` branch, using GitHub's OAuth2.

The server is written in [Crystal](https://crystal-lang.org/)

## Features

- Serve by default a `privpage` branch
- Supports branch prefixes, `privpage-<MY_PREFIX>`
- Do not serve public repositories (no need)

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
- https://priv-page--test--latest.github.privpage.net
- https://priv-page--test-public.github.privpage.net

## Architecture

This is a high level explanation of how this project works.

For more information of how GitHub OAuth works, see [the official documentation](https://developer.github.com/apps/building-github-apps/identifying-and-authorizing-users-for-github-apps/).

1. The client requests a resource
- If the session cookie is present and valid, go to `4.`
- Otherwise, redirects to the provider's OAuth page

2. Provider's (e.g. GitHub) OAuth page
- If successful, redirects to the callback URL (this service)

3. The callback request is received from the OAuth provider
- Get an OAuth token, then store it server-side with a `random_key`
- The `random_key` is set in a session cookie for the client

4. A call is performed to the API to get the resource, which is then served to the client.

## Serving from a documentation directory

GitHub Pages allows to serve from a `/docs` directory, which is not supported by PrivPage.

However, it is possible to create a branch which will have the files of the directory at the root.

For a GitHub Actions example to how build a page site from a directory, [see this file](.github/workflows/documentation.yml).
Of course, adapt it to your needs.

For any question, add a comment to [the related issue](https://github.com/Priv-Page/privpage/issues/5), or ask to the [Gitter chat](https://gitter.im/Priv-Page/community).

## License

Copyright (c) 2020-2021 Julien Reichardt - ISC License
