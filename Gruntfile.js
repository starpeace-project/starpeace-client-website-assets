'use strict';

module.exports = function(grunt) {
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    clean: {
      build: ['build/']
    },

    coffee: {
      compile: {
        expand: true,
        cwd: "src/coffee",
        src: ['**/*.coffee'],
        dest: 'build',
        ext: '.js'
      }
    },

    run: {
      options: {
        failOnError: true
      },
      combine_textures: {
        exec: 'node build/combine-manifest.js node_modules/@starpeace/starpeace-assets/assets build/public'
      },
      export_sandbox: {
        exec: 'node build/export-sandbox.js node_modules/@starpeace/starpeace-assets/assets build/sandbox'
      },
      animate_planets: {
        exec: 'node build/generate-planet-animations.js src/images node_modules/@starpeace/starpeace-assets/assets build/public'
      }
    }
  });

  grunt.registerTask('build', ['coffee:compile']);

  grunt.registerTask('combine', ['build', 'run:combine_textures']);
  grunt.registerTask('export', ['build', 'run:export_sandbox']);
  grunt.registerTask('animate_planets', ['build', 'run:animate_planets']);

  grunt.registerTask('default', ['clean', 'build', 'combine', 'animate_planets']);
}
