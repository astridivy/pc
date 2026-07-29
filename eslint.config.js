//
// eslint.config.js
//
// flat config (eslint >= 9). symlinked to $HOME by link.sh so it catches any
// stray .js that hasn't got a config of its own -- the old .eslintrc.js only
// ever covered ~/src/pc, and eslint 9 ignores eslintrc format entirely.
//
// deps are resolved out of the global npm prefix via NODE_PATH (see
// bashrc/exports). install with:
//   npm i -g eslint eslint_d @eslint/js globals
//

const js = require("@eslint/js")
const globals = require("globals")

// old versions of `globals` ship a key with a trailing space
// ("AudioWorkletGlobalScope "), which eslint >=10 rejects outright. fixed
// upstream in globals 13+, but node resolves this file by its realpath, so a
// stray node_modules anywhere above ~/src/pc can still shadow the good copy
// with an ancient one. normalise defensively so this config cannot be broken
// by whatever happens to be lying around.
const trimKeys = (o) =>
  Object.fromEntries(Object.entries(o).map(([k, v]) => [k.trim(), v]))

module.exports = [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      // flat config dropped `env`, so the globals come in explicitly.
      // without these, recommended's no-undef fires on every console.log
      globals: trimKeys({
        ...globals.browser,
        ...globals.node,
      }),
    },
    rules: {
      "indent": [
        1,
        2,
        {
          "ignoreComments": true,
        },
      ],
      "linebreak-style": 0,
      "quotes": 0,
      "semi": 0,
      "space-before-function-paren": [1, "always"],
      "no-unused-vars": [1, { "args": "after-used" }],
      "comma-dangle": [1, "always-multiline"],
      "no-mixed-spaces-and-tabs": [1, "smart-tabs"],
      "camelcase": 0,
      "no-use-before-define": 0,
      "no-plusplus": 0,
      "consistent-return": 0,
      "no-underscore-dangle": 0,
      "arrow-body-style": 0,
      "no-console": 0,
      "object-curly-spacing": 0,
      "no-multiple-empty-lines": 0,
      "spaced-comment": 0,
    },
  },
]
