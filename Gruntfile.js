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
      audit_textures: {
        exec: 'node build/audit-textures.js assets'
      },
      combine_textures: {
        exec: 'node build/combine-manifest.js assets build/public'
      },
      animate_planets: {
        exec: 'node build/generate-planet-animations.js src/images assets build/public'
      }
    }
  });

  grunt.registerTask('build', ['coffee:compile']);

  grunt.registerTask('audit', ['build', 'run:audit_textures']);
  grunt.registerTask('combine', ['build', 'run:combine_textures']);
  grunt.registerTask('animate_planets', ['build', 'run:animate_planets']);

  grunt.registerTask('default', ['clean', 'build', 'combine', 'animate_planets']);
}
