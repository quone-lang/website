# quone-lang.org

The marketing site for [Quone](https://github.com/quone-lang/compiler),
a typed functional language for R.

Built with [Elm 0.19.1](https://elm-lang.org) and
[elm-ui](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/).
The output is a static SPA: a single `index.html` plus one compiled
`elm.js`, deployable anywhere (Netlify, Vercel, Cloudflare Pages,
GitHub Pages, S3, your own nginx).

## Prerequisites

- Elm 0.19.1 - install via [the Elm guide](https://guide.elm-lang.org/install/elm.html)
  or `brew install elm` on macOS.

That's the only build dependency.

## Local development

```sh
# One-shot build (used by CI / Netlify):
bash build.sh

# Local dev server with hot reload (npm-free option):
elm reactor
# Then open http://localhost:8000/src/Main.elm
```

For a closer-to-production preview, build to `dist/` and serve it with
any static server:

```sh
bash build.sh
cd dist
python3 -m http.server 8000
# Open http://localhost:8000
```

## Deploying

### Netlify (recommended)

The repository ships with a [`netlify.toml`](netlify.toml). Connect the
GitHub repo to Netlify and point it at this directory:

- Base directory: `website/`
- Build command: `bash build.sh`
- Publish directory: `dist/`

Netlify will pick up the SPA `_redirects` rule from `netlify.toml`
automatically, so `/install` and any future routes resolve correctly.

### Static hosting (anywhere else)

Run `bash build.sh` and upload the resulting `dist/` directory. The host
must rewrite all unknown paths to `/index.html` so the SPA can resolve
them client-side - the equivalent of:

```
# nginx
try_files $uri /index.html;
```

```
# Cloudflare Pages
# add a _redirects file containing:
/* /index.html 200
```

## Project layout

```
website/
  elm.json
  build.sh                 # canonical build command
  netlify.toml             # Netlify configuration
  static/
    index.html             # mounts the Elm program
    favicon.svg
  src/
    Main.elm               # Browser.application entrypoint and routing
    Page/
      Home.elm             # hero, feature grid, code examples
      Install.elm          # prerequisites and quickstart
    Ui/
      Theme.elm            # palette, typography, spacing tokens
      Layout.elm           # page chrome (header, footer, sections)
      CodeBlock.elm        # Quone + R syntax highlighting
      Button.elm           # primary and secondary buttons
    Content/
      Examples.elm         # Quone snippets and their generated R
      Pitch.elm            # tagline, features, marketing copy
```

## Design notes

- **Palette** is built around R's logo blue (`#276DC3`) as the primary
  accent. See `src/Ui/Theme.elm`.
- **Typography** pairs Inter (prose) with JetBrains Mono (code), loaded
  from Google Fonts in `static/index.html`.
- **Code blocks** use a hand-rolled tokeniser in `src/Ui/CodeBlock.elm`.
  Quone's keyword set comes from
  [LANGUAGE.md section 3.4](../compiler/docs/LANGUAGE.md). The R
  highlighter recognises base-R keywords (`TRUE`/`FALSE`/`NULL`,
  `function`, `if`/`else`, etc.).
- **Examples** in `src/Content/Examples.elm` show Quone source on the
  left and the generated R on the right, reinforcing the "boring R"
  design principle from
  [LANGUAGE.md section 1.2](../compiler/docs/LANGUAGE.md).

## License

Same as the compiler.
