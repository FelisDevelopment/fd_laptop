import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import path from 'path'
import fs from "fs";

// https://vitejs.dev/config/
export default defineConfig({
    base: process.env.NODE_ENV === 'development' ? '/' : '/web/dist/',
    plugins: [svelte()],
    resolve: {
        alias: {
        $lib: path.resolve(__dirname, './src/lib'),
        },
    },
    // server: {
    //     https: {
    //         key: fs.readFileSync(
    //             path.resolve(__dirname, ".cert/localhost+3-key.pem"),
    //         ),
    //         cert: fs.readFileSync(
    //             path.resolve(__dirname, ".cert/localhost+3.pem"),
    //         ),
    //     },
    //     host: "0.0.0.0", // Allow access from remote computers
    //     port: 5173,
    //     allowedHosts: true,
    // },
    build: {
        target: 'es2022',
        minify: 'esbuild',
        cssMinify: true,
        rollupOptions: {
        output: {
            manualChunks: {
            'vendor': ['svelte'],
            }
        }
        }
    }
})
