module.exports = (grunt) ->

    # Configuration goes here
    grunt.initConfig {
        compass:
            build:
                options:
                    basePath: 'public/'
                    sassDir: 'sass'
                    cssDir: 'stylesheets'
                    imagesDir: 'images'
                    fontsDir: 'fonts'
        coffee:
#            node:
#                files: [
#                    { src: 'server.coffee', dest: 'server.js' }
#                    { expand: true, cwd: 'server/', src: ['**/*.coffee'], dest: 'server/', ext: '.js' }
#                ]
            angular:
                options:
                    join: true
                src: ['public/scripts/app.coffee', 'public/scripts/**/*.coffee', '!public/scripts/compiled/app.src.coffee']
                dest: 'public/scripts/compiled/app.js'
        ngtemplates:
            build:
                options:
                    base: 'public/'
                    prepend: '/'
                    module: 'bitcoinApp'
                    htmlmin:
                        collapseWhitespace: true
                        removeComments: true
                src: 'public/templates/**/*.html'
                dest: 'public/scripts/compiled/templates.js'
        concat:
            libraries:
                files: [
                    {
                        src: [
                            'public/scripts/vendor/jquery-2.0.3.js'
                            'public/scripts/vendor/md5.js'
                            'public/scripts/vendor/underscore.js'
                            'public/scripts/vendor/moment.js'
                            'public/scripts/vendor/angular.js'
                            'public/scripts/vendor/angular-route.js'
                            'public/scripts/vendor/angular-resource.js'
                            'public/scripts/vendor/angular-cookies.js'
                            'public/scripts/vendor/angular-interval.js'
                            'public/scripts/vendor/angular-sanitize.js'
                            'public/scripts/vendor/ui-utils.js'
                            'public/scripts/vendor/ui-bootstrap.js'
                            'public/scripts/vendor/highcharts.src.js'
                        ]
                        dest: 'public/scripts/compiled/libraries.js'
                    }
                    {
                        src: [
                            'public/scripts/vendor/jquery-2.0.3.min.js'
                            'public/scripts/vendor/md5.js'
                            'public/scripts/vendor/underscore-min.js'
                            'public/scripts/vendor/moment.min.js'
                            'public/scripts/vendor/angular.min.js'
                            'public/scripts/vendor/angular-route.min.js'
                            'public/scripts/vendor/angular-resource.min.js'
                            'public/scripts/vendor/angular-cookies.min.js'
                            'public/scripts/vendor/angular-interval.min.js'
                            'public/scripts/vendor/angular-sanitize.min.js'
                            'public/scripts/vendor/ui-utils.min.js'
                            'public/scripts/vendor/ui-bootstrap.min.js'
                            'public/scripts/vendor/highcharts.js'
                        ]
                        dest: 'public/scripts/compiled/libraries.min.js'
                    }
                ]
        ngmin:
            angular:
                src: 'public/scripts/compiled/app.js'
                dest: 'public/scripts/compiled/app.annotate.js'
        uglify:
            angular:
                options: mangle: false
                src: 'public/scripts/compiled/app.js'
                dest: 'public/scripts/compiled/app.min.js'
        watch:
            compass:
                files: ['public/sass/**/*', 'public/images/**/*']
                tasks: ['compass']
#            node:
#                files: ['server.coffee', 'server/**/*.coffee']
#                tasks: ['coffee:node']
            angular:
                files: ['public/scripts/**/*.coffee', '!public/scripts/compiled/app.src.coffee']
                tasks: ['coffee:angular', 'ngmin:angular', 'uglify:angular']
            templates:
                files: ['public/templates/**/*.html']
                tasks: ['ngtemplates']
    }

    # Load plugins here
    grunt.loadNpmTasks('grunt-contrib-coffee')
    grunt.loadNpmTasks('grunt-contrib-concat')
    grunt.loadNpmTasks('grunt-contrib-compass')
    grunt.loadNpmTasks('grunt-contrib-clean')
    grunt.loadNpmTasks('grunt-contrib-uglify')
    grunt.loadNpmTasks('grunt-contrib-watch')
    grunt.loadNpmTasks('grunt-ngmin')
    grunt.loadNpmTasks('grunt-angular-templates')

    # Define your tasks here
    #grunt.registerTask('default', ['compass', 'coffee'])
    grunt.registerTask('default', ['compass', 'coffee', 'ngtemplates', 'concat', 'ngmin', 'uglify'])
