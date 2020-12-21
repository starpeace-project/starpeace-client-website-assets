# starpeace-client-website-assets
## Development

Local development can be accomplished in a few commands. The following build-time dependencies must be installed:

* [Node.js](https://nodejs.org/en/) javascript runtime and [npm](https://www.npmjs.com/get-npm) package manager
* [Grunt](https://gruntjs.com/) task manager

Retrieve copy of repository and navigate to root:

```
$ git clone https://github.com/starpeace-project/starpeace-client-website-assets.git
$ cd starpeace-client-website-assets
```

Install starpeace-client-website-assets dependencies:

```
$ npm install
```

Raw assets can be compiled and planet animations generated with default or ```combine``` grunt target:

```
$ grunt
$ grunt combine
```
