import js from '@eslint/js'

export default [
    js.configs.recommended,
    {
        rules: {
            'no-unused-vars': 'warn',
            'no-console': 'off',
            'semi': ['error', 'never'],
            'quotes': ['error', 'single'],
        },
    },
    {
        ignores: ['node_modules/**', 'coverage/**'],
    },
]
