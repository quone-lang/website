# quone-lang.org

The marketing site for [Quone](https://github.com/quone-lang/compiler),
a typed functional language that compiles to readable R.

Built with [Elm 0.19.1](https://elm-lang.org) and
[`elm-ui`](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/).
The output is a static single-page site -- one `index.html` plus one compiled
`elm.js` -- deployable on any static host.

## Develop

For the canonical production-style build, you need Node/npm and Python 3.
`build.sh` installs Elm 0.19.1 for the build itself, compiles the site,
and fingerprints the resulting bundle as `elm-<hash>.js`.

For a live-reloading local workflow, use:

```sh
npm install
npm run dev
```

That starts a watcher at `http://127.0.0.1:4174`. Changes under `src/`,
`static/`, or `elm.json` trigger a rebuild, and the browser reloads after
each successful rebuild.

If you want to use `elm reactor` while editing `src/`, install Elm 0.19.1
yourself (`brew install elm` on macOS, or follow the
[Elm guide](https://guide.elm-lang.org/install/elm.html)).

```sh
npm install
bash build.sh
npm run serve:dist
```

That preview server serves the built single-page site from `dist/`.

Hero examples on the home page come from `website/snippets/*.Q`. The script
`scripts/generate_examples_data.py` runs `quonec build` and overwrites
`src/Content/ExamplesData.elm`. On hosts without `quonec` (including
Netlify), the script keeps the last committed `ExamplesData.elm`. After
changing snippets locally, build `quonec` in `../compiler` (or set
`QUONEC` to the binary), then run `python3 scripts/generate_examples_data.py`
from `website/`.

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

For any other host, run `bash build.sh` and upload `dist/`.

## Social card

`static/social-card-share.png` (the OG image referenced from
`static/index.html`) is rendered from `src/SocialCard.elm`, which
reuses the same theme, fonts, and `Ui.CodeBlock` highlighter as the
rest of the site. To regenerate it after a brand or copy change:

```sh
npm install
npx playwright install chromium  # first time only
node scripts/render-social-card.cjs
```

The script compiles `SocialCard.elm`, mounts it on a temporary 1200x630
page with the self-hosted woff2 fonts inlined as data URIs, and
screenshots the result via Playwright's bundled Chromium. Commit the
updated PNG.

## Tests

The repo ships with a small Playwright smoke suite that covers the single-page
copy, install section, navigation, and theme toggle.

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
  snippets/*.Q               # hero Quone sources (fed to quonec by the generator)
  scripts/generate_examples_data.py
  scripts/render-social-card.cjs   # screenshots SocialCard.elm into static/social-card-share.png
  static/index.html          # mounts the Elm program
  src/
    Main.elm                 # Browser.document entrypoint
    SocialCard.elm           # 1200x630 social card (rendered to PNG, see Social card section)
    Page/Home.elm            # single page content
    Ui/{Theme,Layout,CodeBlock,Button}.elm
    Content/{Examples,ExamplesData,Pitch}.elm
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
