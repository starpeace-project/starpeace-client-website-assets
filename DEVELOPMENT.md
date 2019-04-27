# starpeace-website-client-assets
## Development

Local development can be accomplished in a few commands. The following build-time dependencies must be installed:

* [Node.js](https://nodejs.org/en/) javascript runtime and [npm](https://www.npmjs.com/get-npm) package manager
* [Grunt](https://gruntjs.com/) task manager

Retrieve copy of repository and navigate to root:

```
$ git clone https://github.com/starpeace-project/starpeace-website-client-assets.git
$ cd starpeace-website-client-assets
```

Install starpeace-website-client-assets dependencies:

```
$ npm install
```

Raw assets can be compiled to game-ready with default or ```combine``` grunt target:

```
$ grunt
$ grunt combine
```

Planet animations can be generated with ```animate_planets``` target:

```
$ grunt animate_planets
```
