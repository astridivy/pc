module.exports = {
  "root": true,
  "env": {
    "browser": true,
    "node": true,
    "jasmine": true,
    "protractor": true,
    "es6": true
  },
  "parser": "@babel/eslint-parser",
  "extends": [
    "eslint:recommended",
  ],
  "plugins": [
  ],
  "parserOptions": {
    "sourceType": "module",
    "ecmaVersion": 2018,
    "babel": {
      "requireConfigFile": false,
    },
  },
  //"settings": {
  //"react": {
  //"pragma": 'Cute'
  //}
  //},
  "rules": {
    "indent": [
      1,
      2,
      {
        "ignoreComments": true
      }
    ],
    "linebreak-style": 0,
    "quotes": 0,
    "semi": 0,
    "space-before-function-paren": [1, "always"],
    "no-unused-vars": [1, {"args": "after-used"}],
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
  }
};
