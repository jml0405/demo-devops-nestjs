import js from '@eslint/js'

export default [
    js.configs.recommended,
    // ── Node.js globals for all source files ─────────────────────────────────
    {
        languageOptions: {
            globals: {
                console: 'readonly',
                process: 'readonly',
                __dirname: 'readonly',
                __filename: 'readonly',
                Buffer: 'readonly',
                setTimeout: 'readonly',
                clearTimeout: 'readonly',
                setInterval: 'readonly',
                clearInterval: 'readonly',
                URL: 'readonly',
            },
        },
        rules: {
            'no-unused-vars': 'warn',
            'no-console': 'off',
            'semi': ['error', 'never'],
            'quotes': ['error', 'single'],
        },
    },
    // ── Jest globals for test files ───────────────────────────────────────────
    {
        files: ['**/*.test.js', '**/*.spec.js'],
        languageOptions: {
            globals: {
                describe: 'readonly',
                test: 'readonly',
                it: 'readonly',
                expect: 'readonly',
                jest: 'readonly',
                beforeEach: 'readonly',
                afterEach: 'readonly',
                beforeAll: 'readonly',
                afterAll: 'readonly',
            },
        },
    },
    {
        ignores: ['node_modules/**', 'coverage/**'],
    },
]
