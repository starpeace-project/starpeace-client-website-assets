'use strict';

module.exports = function(grunt) {
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    clean: {
      build: ['build/']
    },

    sass: {
      dist: {
        options: {
          sourceMap: false,
          outputStyle: 'compact'
        },
        files: [{
          expand: true,
          flatten: true,
          src: ['src/webapp/sass/*.sass'],
          dest: 'build/tmp',
          ext: '.css'
        }]
      }
    },

    cssmin: {
      target: {
        files: {
          'build/web/assets/assets-main.min.css': ['build/tmp/*.css']
        }
      }
    },

    coffee: {
      asset_compile: {
        expand: true,
        flatten: true,
        cwd: "src/",
        src: ['webapp/coffee/**/*.coffee'],
        dest: 'build/tmp/',
        ext: '.js'
      },
      compile: {
        expand: true,
        cwd: "src/coffee",
        src: ['**/*.coffee'],
        dest: 'build',
        ext: '.js'
      }
    },

    uglify: {
      dist: {
        files: {
          'build/web/assets/assets-main.min.js': ['build/tmp/*.js']
        }
      }
    },

    haml: {
      compile: {
        files: {
          'build/web/land.html': 'src/webapp/haml/land.haml'
        }
      }
    },

    copy: {
      misc_images: {
        files: [
          {expand: true, flatten: true, src: ['src/images/misc/*'], dest: 'build/public', filter: 'isFile'}
        ]
      },
      sounds: {
        files: [
          {expand: true, flatten: true, src: ['src/sounds/music/*'], dest: 'build/public', filter: 'isFile', rename: function (dest, src) { return dest + '/music.' + src }}
        ]
      }
    },

    run: {
      options: {
        failOnError: true
      },
      audit_textures: {
        exec: 'node build/audit-textures.js src/images'
      },
      cleanup_textures: {
        exec: 'node build/cleanup-textures.js src/images legacy'
      },
      combine_textures: {
        exec: 'node build/combine-manifest.js src build/public'
      },
      animate_planets: {
        exec: 'node build/generate-planet-animations.js src/images build/public'
      },
      server: {
        exec: 'node build/server.js'
      }
    }
  });

  grunt.registerTask('build', ['coffee:compile','copy:misc_images', 'copy:sounds']);
  grunt.registerTask('build_server', ['clean', 'sass', 'cssmin', 'coffee:asset_compile', 'uglify', 'haml', 'copy:misc_images', 'copy:sounds']);

  grunt.registerTask('audit', ['build', 'run:audit_textures']);
  grunt.registerTask('cleanup', ['build', 'run:cleanup_textures']);
  grunt.registerTask('combine', ['build', 'run:combine_textures']);
  grunt.registerTask('animate_planets', ['build', 'run:animate_planets']);

  grunt.registerTask('default', ['clean', 'build', 'combine', 'animate_planets']);
  grunt.registerTask('server', ['build_server', 'coffee:compile', 'run:server']);
}
