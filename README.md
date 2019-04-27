
# starpeace-website-client-assets

[![GitHub release](https://img.shields.io/github/release/starpeace-project/starpeace-website-client-assets.svg)](https://github.com/starpeace-project/starpeace-website-client-assets/releases/)
[![Build Status](https://travis-ci.org/starpeace-project/starpeace-website-client-assets.svg)](https://travis-ci.org/starpeace-project/starpeace-website-client-assets)
[![GitHub license](https://img.shields.io/github/license/starpeace-project/starpeace-website-client-assets.svg)](https://github.com/starpeace-project/starpeace-website-client-assets/blob/master/LICENSE)

Compilation logic and tools for [STARPEACE](https://www.starpeace.io) to process and package gameplay images, sounds, and baseline simulation configurations for client website integration.

## Documentation

Assets and gameplay configurations are retrieved from [starpeace-assets](https://github.com/starpeace-project/starpeace-assets).

## Security Vulnerabilities

If you discover a security vulnerability within STARPEACE website, please send an e-mail to security@starpeace.io or open a [GitHub issue](https://github.com/starpeace-project/starpeace-website-client/issues). All security vulnerabilities will be promptly addressed.

## Development

Please see [development manual](./DEVELOPMENT.md) for starpeace-website-client-assets development instructions and [read the contributing guide](https://github.com/starpeace-project/starpeace-website-client/blob/master/CONTRIBUTING.md) to learn more about project.

## Build and Deployment

After building repository with grunt ```combine```, game-ready assets are compiled and placed within the ```/build/public/``` folder. These resources should be served as static assets from web application and can be cached if desired.

### cdn.starpeace.io

Repository is currently deployed to and hosted with AWS S3. Changes pushed to repository will activate webhook to AWS CodePipeline, triggering automatic rebuild and deployment of website resources.

## Asset Tools
### Combine

combine-manifest.js is executed with grunt ```combine``` target and provides logic to combine and optimize raw assets as well as generate description metadata to be used with game client


## License

Source code of starpeace-website-client-assets used to process and package content is licensed under the [MIT license](https://opensource.org/licenses/mit-license.php).
