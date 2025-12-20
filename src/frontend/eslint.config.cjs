const reactPlugin = require('eslint-plugin-react')
const reactRecommended = require('eslint-plugin-react/configs/recommended')

module.exports = [
  // Global ignores (replace .eslintignore)
  {
    ignores: ['dist/**', 'node_modules/**', 'public/**'],
  },
  // React recommended rules (flat config)
  reactRecommended,
  // Project-specific settings and overrides
  {
    files: ['src/**/*.{js,jsx}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        window: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
      },
    },
    plugins: {
      react: reactPlugin,
    },
    rules: {
      'react/react-in-jsx-scope': 'off',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
]
