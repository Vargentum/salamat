"use strict"
LIVERELOAD_PORT = 35729
lrSnippet = require("connect-livereload")(port: LIVERELOAD_PORT)
mountFolder = (connect, dir) ->
  connect.static require("path").resolve(dir)

module.exports = (grunt) ->
  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    
    tag:
      banner: "/*!\n" + " * <%= pkg.name %>\n" + " * <%= pkg.title %>\n" + " * @author <%= pkg.author %>\n" + " * <%= pkg.url %>\n" + " */\n"


    connect:
      options:
        port: 9999
        hostname: "127.0.0.1"

      livereload:
        options:
          middleware: (connect) ->
            [
              lrSnippet
              mountFolder(connect, "app")
            ]

   
    clean: [
      "./temp"
      "./app"
    ]


    copy: 
      webfont:
        expand: on
        cwd: './src/webfont'
        src: ['**/*']
        dest: './app/assets' 

      docs_assets:
        expand: on
        cwd: "./app/assets/"
        src: ["**"]
        dest: "./app/docs/assets/" 



    concat:
      plugins:
        src: ["./src/plugins/{,**/}*.js"]
        dest: "./app/assets/js/<%= pkg.name %>-plugins.js"

      components:
        src: ["./src/components/{,**/}*.coffee"]
        dest: "./temp/components.coffee"

      styles:
        src: [
          './src/base-styles/core.styl'
          "./src/components/{,**/}*.styl"
        ]
        dest: "./temp/styles.styl"

      options:
        stripBanners: true
        nonull: true


    coffee:
      components:
        src: ["<%= concat.components.dest %>"]
        dest: "./app/assets/js/<%= pkg.name %>-components.js"


    uglify:
      plugins:
        src: ["<%= concat.plugins.dest %>"]
        dest: "./app/assets/js/<%= pkg.name %>-plugins.min.js"

      components:
        src: ["<%= coffee.components.dest %>"]
        dest: "./app/assets/js/<%= pkg.name %>-components.min.js"


    stylus:
      styles:
        src: ["<%= concat.styles.dest %>"]
        dest: "./temp/unprefixed-styles.css"

        options:
          paths: [
            "./src/base-styles/"
            "./app/assets/css/"
            "./app/assets/fonts/"
            "./app/assets/img/"
            "./node_modules/jeet/stylus/"
          ]
          import: [
            "jeet"
          ]
          compress: no
          urlfunc: "data"


    autoprefixer:
      styles:
        src: ["<%= stylus.styles.dest %>"]
        dest: "./app/assets/css/<%= pkg.name %>-styles.css"

        options:
          browsers: ["last 2 version", "ie 9"]

    cssmin:
      styles:
        src: ["<%= pkg.name %>-styles.css"]
        cwd: "./app/assets/css/"
        dest: "./app/assets/css/"
        ext: ".min.css"
        expand: on


    jade:
      compile:
        expand: on
        flatten: on
        src: ['./src/components/*.jade']  #core files without components
        dest: './temp'
        ext: '.html'
        options:
          pretty: on


    htmlmin:
      markup:
        options:
          removeComments: on
          collapseWhitespace: on
          removeAttributeQuotes: on
        expand: on  
        flatten: true
        src: ["./temp/{,**/}*.html"]
        dest: './app'
        ext: '.html'



    webfont:
      svg:
        src: ['./src/graphics/{,**/}*.svg']
        dest: './app/assets/font'
        destCss: './src/base-styles/graphics-map'
        options:
          stylesheet: 'styl'
          relativeFontPath: '../font'
          types: "eot,woff"
          syntax: 'bootstrap'


    sprite:
      png:
        src: ['./src/graphics/{,**/}*.png']
        destImg: './app/assets/img/<%= pkg.name %>-sprite.png'
        destCSS: './src/base-styles/graphics-map/sprites.styl'
        imgPath: '../img/<%= pkg.name %>-sprite.png'
        algorithm: 'binary-tree'
        padding: 2
        engine: 'pngsmith'
        cssFormat: 'stylus'


    open:
      server:
        path: "http://localhost:<%= connect.options.port %>"


     dss:
      docs:
        src: ["<%= stylus.styles.src %>"]
        dest: "app/docs/"
        options:
          include_empty_files: no
          template: "src/docs/"


    watch:
      stylus:
        files: "./src/{,**/}*.styl"
        tasks: ["process-styles", "dss"]

      plugins:
        files: "<%= concat.plugins.src %>"
        tasks: ["process-plugins"]

      components:
        files: "<%= concat.components.src %>"
        tasks: ["process-components"]

      markup:
        files: "./src/{,**/}*.jade"
        tasks: ["process-markup"]

      sprite:
        files: "<%= sprite.png.src %>"
        tasks: ["sprite"]
        options:
          reload: on

      webfont:
        files: "<%= webfont.svg.src %>"
        tasks: ["webfont"]
        options:
          reload: on

      livereload:
        options:
          livereload: LIVERELOAD_PORT

        files: ["src/**"]


  grunt.registerTask "process-html", [
    "includes"
  ]
  grunt.registerTask "process-graphics", [
    "sprite"
    "webfont"
  ]
  grunt.registerTask "process-styles", [
    "concat:styles"
    "stylus"
    "autoprefixer"
    "cssmin"
  ]
  grunt.registerTask "process-markup", [
    "jade"
    "htmlmin"
  ]
  grunt.registerTask "process-plugins", [
    "concat:plugins"
    "uglify:plugins"
  ]
  grunt.registerTask "process-components", [
    "concat:components"
    "coffee"
    "uglify:components"
  ]
  grunt.registerTask "generate_docs",[
    "dss"
    "copy:docs_assets"
  ]
  grunt.registerTask "build", [
    "clean"
    "copy:webfont"
    "process-graphics"
    "concat"
    "process-plugins"
    "process-components"
    "process-styles"
    "process-markup"
    "generate_docs"
  ]
  grunt.registerTask "default", ["build"]
  grunt.registerTask "server", [
    "build"
    "connect:livereload"
    "open"
    "watch"
  ]
  grunt.registerTask "s", ["server"]
  return
