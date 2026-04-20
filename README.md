# quone-lang.org

The marketing site for [Quone](https://github.com/quone-lang/compiler),
a typed functional language that compiles to readable R.

Built with [Elm 0.19.1](https://elm-lang.org) and
[`elm-ui`](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/).
The output is a static SPA -- one `index.html` plus one compiled
`elm.js` -- deployable on any static host.

## Develop

For the canonical production-style build, you need Node/npm and Python 3.
`build.sh` installs Elm 0.19.1 for the build itself, compiles the site,
and fingerprints the resulting bundle as `elm-<hash>.js`.

If you want to use `elm reactor` while editing `src/`, install Elm 0.19.1
yourself (`brew install elm` on macOS, or follow the
[Elm guide](https://guide.elm-lang.org/install/elm.html)).

```sh
npm install
bash build.sh
npm run serve:dist
```

That preview server rewrites unknown paths back to `index.html`, so `/install`
and any future SPA routes behave the same way they do on Netlify.

For `elm reactor` during development:

```sh
elm reactor
# then open http://localhost:8000/src/Main.elm
```

## Deploy

[Netlify](https://www.netlify.com/) is the recommended host; the
repo ships with [`netlify.toml`](netlify.toml).

| Setting             | Value          |
| ------------------- | -------------- |
| Base directory      | _(leave blank)_ |
| Build command       | `bash build.sh`|
| Publish directory   | `dist/`        |

For any other host, run `bash build.sh` and upload `dist/`. The host
must rewrite unknown paths to `/index.html` so the SPA routes
client-side (e.g. nginx `try_files $uri /index.html;`, or a
`/* /index.html 200` line for Cloudflare Pages).

## Tests

The repo ships with a small Playwright smoke suite that covers the home
page, install route, keyboard tab navigation, and the compact/mobile
hero shell.

```sh
npm install
npx playwright install chromium
npm test
```

## Layout

```
website/
  build.sh                   # canonical build command
  netlify.toml               # Netlify configuration
  static/index.html          # mounts the Elm program
  src/
    Main.elm                 # Browser.application entrypoint + routing
    Page/{Home,Install}.elm  # pages
    Ui/{Theme,Layout,CodeBlock,Button}.elm
    Content/{Examples,Pitch}.elm
```

The Quone keyword set used by `Ui/CodeBlock.elm` mirrors
[LANGUAGE.md section 3.4](https://github.com/quone-lang/compiler/blob/main/docs/LANGUAGE.md);
keep it in sync when the language adds keywords. The "boring R"
design principle that drives the side-by-side examples is
[LANGUAGE.md section 1.2](https://github.com/quone-lang/compiler/blob/main/docs/LANGUAGE.md).

## Sibling repos

- **[quone-lang/compiler](https://github.com/quone-lang/compiler)** --
  the `quonec` compiler.
- **[quone-lang/quone](https://github.com/quone-lang/quone)** -- R
  companion package.
- **[quone-lang/examples](https://github.com/quone-lang/examples)** --
  sample Quone programs.

## License

[MIT](https://github.com/quone-lang/compiler/blob/main/LICENSE),
matching the compiler.
