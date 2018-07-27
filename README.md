
# starpeace-website-client-assets

[![Build Status](https://travis-ci.org/ronappleton/starpeace-website-client-assets.svg)](https://travis-ci.org/ronappleton/starpeace-website-client-assets)

Assets for [STARPEACE](https://www.starpeace.io), including gameplay images, sounds, and compilation tools for client integration.

## Official Documentation

Documentation for client gameplay can be found on the [STARPEACE website](https://docs.starpeace.io).

## Roadmap

Development and gameplay roadmap can be found on the [STARPEACE website](https://www.starpeace.io/release).

## Security Vulnerabilities

If you discover a security vulnerability within STARPEACE website, please send an e-mail to security@starpeace.io or open a [GitHub issue](https://github.com/ronappleton/starpeace-website-client/issues). All security vulnerabilities will be promptly addressed.

## Development

Local development can be accomplished in a few commands. The following build-time dependencies must be installed:

* [Node.js](https://nodejs.org/en/) javascript runtime and [npm](https://www.npmjs.com/get-npm) package manager
* [Grunt](https://gruntjs.com/) task manager

Retrieve copy of repository and navigate to root:

```
$ git clone https://github.com/ronappleton/starpeace-website-client-assets.git
$ cd starpeace-website-client-assets
```

Install starpeace-website-client-assets dependencies:

```
$ npm install
```

Repository contains server scripts and a server to browse raw assets. Different grunt targets execute each script, explained further below:


```
$ grunt audit
$ grunt cleanup
```

Raw assets can be compiled to game-ready with default or ```combine``` grunt target:

```
$ grunt
$ grunt combine
```

``Note: server was used in past for land auditing and may no longer work''
A simple server is also provided to browse raw assets, accessible at [127.0.0.1:11015](http://127.0.0.1:11015) using ```server``` grunt target:

```
$ grunt server
```

## Build and Deployment

After building repository with grunt ```combine```, game-ready assets are compiled and placed within the ```/build/public/``` folder. These resources should be served as static assets from web application and can be cached if desired.

## Asset Tools
### Audit

audit-textures.js is executed with grunt ```audit``` target and provides a read-only analysis of game image assets, including checking for various land metadata and images consistency problems

### Cleanup

cleanup-textures.js is executed with grunt ```cleanup``` target and provides automated logic to fix several metadata and image problems, requiring interaction and confirmation from command-line during execution

### Combine

combine-manifest.js is executed with grunt ```combine``` target and provides logic to combine and optimize raw assets as well as generate description metadata to be used with game client

## Legacy Assets

Changes to legacy assets, including removal from gameplay (moved to ```/legacy/``` folder), explained below:

### Land
* *all* - refactor - renamed land image files to strict format
* border.255.ini - bug fix - changed MapColor to 0
* land.0.ini - bug fix - flipped MapColor endian value (4358782 or #42827E to 8290882 or #7E8242)
* border.bmp - refactor - renamed to land.255.border0.bmp
* border1.bmp - refactor - renamed to land.255.border1.bmp
* special images - refactor - renamed to tree.<zone>.<variant>.bmp

### Maps
* Fraternite - renamed - renamed assets to remove special character (�)
* Liberte - removed - duplicate of Zyrane assets (same problems)
* StarpeaceU - removed - duplicate of Zyrane assets (same problems)
* Zyrane - removed - missing almost all matching land tiles (117/130)


## License

STARPEACE website is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
