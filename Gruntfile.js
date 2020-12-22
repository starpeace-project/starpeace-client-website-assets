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
        cwd: 'src',
        src: ['**/*.coffee'],
        dest: 'build',
        ext: '.js'
      }
    },

    run: {
      options: {
        failOnError: true
      },
      combine_assets: {
        exec: 'node build/combine-assets.js assets node_modules/@starpeace/starpeace-assets/assets build/public'
      },
      export_sandbox: {
        exec: 'node build/export-sandbox.js node_modules/@starpeace/starpeace-assets/assets build/sandbox'
      },
      backfill_towns: {
        exec: 'node build/backfill-towns.js node_modules/@starpeace/starpeace-assets/assets build/towns'
      }
    }
  });

  grunt.registerTask('build', ['coffee:compile']);

  grunt.registerTask('combine', ['build', 'run:combine_assets']);
  grunt.registerTask('export', ['build', 'run:export_sandbox']);
  grunt.registerTask('towns', ['build', 'run:backfill_towns']);

  grunt.registerTask('default', ['clean', 'build', 'combine']);
}
