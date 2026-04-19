# quone-lang.org

The marketing site for [Quone](https://github.com/quone-lang/compiler),
a typed functional language that compiles to readable R.

Built with [Elm 0.19.1](https://elm-lang.org) and
[`elm-ui`](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/).
The output is a static SPA -- one `index.html` plus one compiled
`elm.js` -- deployable on any static host.

## Develop

Install Elm 0.19.1 (`brew install elm` on macOS, or follow the
[Elm guide](https://guide.elm-lang.org/install/elm.html)). That is
the only build dependency.

```sh
bash build.sh        # one-shot build into dist/ (used by CI)
elm reactor          # local dev server with hot reload
                     # then open http://localhost:8000/src/Main.elm
```

For a production-style preview:

```sh
bash build.sh
python3 -m http.server --directory dist 8000
```

## Deploy

[Netlify](https://www.netlify.com/) is the recommended host; the
repo ships with [`netlify.toml`](netlify.toml).

| Setting             | Value          |
| ------------------- | -------------- |
| Base directory      | `website/`     |
| Build command       | `bash build.sh`|
| Publish directory   | `dist/`        |

For any other host, run `bash build.sh` and upload `dist/`. The host
must rewrite unknown paths to `/index.html` so the SPA routes
client-side (e.g. nginx `try_files $uri /index.html;`, or a
`/* /index.html 200` line for Cloudflare Pages).

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
