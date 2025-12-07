import { defineConfig } from '@rspack/cli';
import { rspack } from '@rspack/core';

import * as path from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';

// Define __dirname equivalent in ES module scope
//@ts-ignore
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
//@ts-ignore
const req = createRequire(import.meta.url);

export default defineConfig({
  context: __dirname,
  target: 'node',
  entry: {
    main: ['./src/main.ts'],
  },
  ignoreWarnings: [
    /Critical dependency: the request of a dependency is an expression/,
  ],
  resolve: {
    extensions: ['...', '.ts'],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: {
          loader: 'builtin:swc-loader',
          options: {
            jsc: {
              parser: {
                syntax: 'typescript',
                decorators: true,
              },
              transform: {
                legacyDecorator: true,
                decoratorMetadata: true,
              },
            },
          },
        },
      },
    ],
  },
  optimization: {
    minimizer: [
      new rspack.SwcJsMinimizerRspackPlugin({
        minimizerOptions: {
          // We need to disable mangling and compression for class names and function names for Nest.js to work properly
          // The execution context class returns a reference to the class/handler function, which is for example used for applying metadata using decorators
          // docs.nestjs.com
          compress: {
            keep_classnames: true,
            keep_fnames: true,
          },
          mangle: {
            keep_classnames: true,
            keep_fnames: true,
          },
        },
      }),
    ],
  },
  externalsType: 'commonjs',
  externals: [
    ({ request }, callback) => {
      const lazyImports = [
        '@nestjs/core',
        '@nestjs/microservices',
        '@nestjs/platform-express',
        'cache-manager',
        'class-validator',
        'class-transformer',
        // ADD THIS
        '@nestjs/microservices/microservices-module',
        '@nestjs/websockets',
        'socket.io-adapter',
        'utf-8-validate',
        'bufferutil',
        'kerberos',
        '@mongodb-js/zstd',
        'snappy',
        '@aws-sdk/credential-providers',
        'mongodb-client-encryption',
        '@nestjs/websockets/socket-module',
        'bson-ext',
        'snappy/package.json',
        'aws4',
      ];
      if (!request) {
        throw new Error('Request object is empty');
      }
      if (!lazyImports.includes(request)) {
        return callback();
      }
      try {
        req.resolve(request);
      } catch (err) {
        callback(undefined, request);
      }
      callback();
    },
  ],
});
