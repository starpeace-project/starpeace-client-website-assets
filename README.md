
# starpeace-website-client-assets

[![Build Status](https://travis-ci.org/ronappleton/starpeace-website-client-assets.svg)](https://travis-ci.org/ronappleton/starpeace-website-client-assets)

Assets for [Starpeace](https://www.starpeace.io), including gameplay images, sounds, and compilation tools for client integration.

## Official Documentation

Documentation for client gameplay can be found on the [Starpeace website](https://docs.starpeace.io).

## Roadmap

Development and gameplay roadmap can be found on the [Starpeace Community Development website](https://www.starpeace.ovh/).

## Security Vulnerabilities

If you discover a security vulnerability within Starpeace website, please send an e-mail to admin@starpeace.ovh or open a [GitHub issue](https://github.com/ronappleton/starpeace-website-client/issues). All security vulnerabilities will be promptly addressed.

## Development

Local development can be accomplished in a few commands. The following build-time dependencies must be installed:

* [Node.js](https://nodejs.org/en/) javascript runtime and [npm](https://www.npmjs.com/get-npm) package manager
* [Grunt](https://gruntjs.com/) task manager

Retrieve copy of repository and navigate to root:

```
$ git clone https://github.com/ronappleton/starpeace-website-client.git
$ cd starpeace-website-client
```

Install starpeace-website-client dependencies:

```
$ npm install
```

Repository contains server scripts and a server to browse raw assets. Different grunt targets execute each script, explained further below:


```
$ grunt audit
$ grunt cleanup
$ grunt combine
```

Raw assets can be compiled to game-ready with default or ```build``` grunt target:

```
$ grunt
$ grunt build
```

A simple server is also provided to browse raw assets, accessible at [127.0.0.1:11015](http://127.0.0.1:11015) using ```server``` grunt target:

```
$ grunt server
```

## Build and Deployment

After building repository, game-ready assets are compiled and placed within the ```/build/public/``` folder. These resources should be served as static assets from web application and can be cached if desired.

## Asset Tools
### Audit

audit-textures.js is executed with grunt ```audit``` target and provides a read-only analysis of game image assets, including checking for various land metadata and images consistency problems

### Cleanup

cleanup-textures.js is executed with grunt ```cleanup``` target and provides automated logic to fix several metadata and image problems, requiring interaction and confirmation from command-line during execution

### Combine

combine-textures.js is executed with grunt ```combined``` target and provides logic to combine and optimize raw assets as well as generate description metadata to be used with game client

## Legacy Assets

Changes to legacy assets, including removal from gameplay (moved to ```/legacy/``` folder), explained below:

### Land
* *all* - refactor - renamed land image files to strict format
* border.255.ini - bug fix - changed MapColor to 0
* land.0.ini - bug fix - flipped MapColor endian value (4358782 or #42827E to 8290882 or #7E8242)
* border.bmp - refactor - renamed to land.255.border0.bmp
* border1.bmp - refactor - renamed to land.255.border1.bmp
* special images - removed for now - unused by any maps and MapColor collisions with each other
    * special.052.Grass.ini
    * special.053.Grass.ini
    * special.054.Grass.ini
    * special.055.Grass.ini
    * special.056.Grass.ini
    * special.057.Grass.ini
    * special.058.Grass.ini
    * special.059.Grass.ini
    * special.060.Grass.ini
    * special.062.Grass.ini
    * special.116.MidGrass.ini
    * special.117.MidGrass.ini
    * special.118.MidGrass.ini
    * special.119.MidGrass.ini
    * special.120.MidGrass.ini
    * special.180.DryGround.ini
    * special.181.DryGround.ini
    * special.182.DryGround.ini
    * special.183.DryGround.ini
    * special.184.DryGround.ini
    * special.185.DryGround.ini

### Maps
* Fraternite - renamed - renamed assets to remove special character (é)
* Liberte - removed - duplicate of Zyrane assets (same problems)
* StarpeaceU - removed - duplicate of Zyrane assets (same problems)
* Zyrane - removed - missing almost all matching land tiles (117/130)


## License

Starpeace website is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
