
WIDTH = 512
HEIGHT = 512

CAMERA_D = 5.25

PNG = require('pngjs').PNG

THREE = require('three')
THREEP = require('postprocessing')
gl = require('gl')(WIDTH, HEIGHT, {})

fs = require('fs')


class PlanetAnimationRenderer
  @WIDTH: WIDTH
  @HEIGHT: HEIGHT
  @ASPECT: @WIDTH / @HEIGHT

  ###
  * legacy code supporting shaders:
  *
  * composer = new THREEP.EffectComposer(renderer, {})
  * composer.readBuffer = renderTarget
  * composer.writeBuffer = renderTarget.clone()
  * composer.addPass(new THREEP.RenderPass(scene, camera, { clear: true, clearColor: 0x00ffff, clearAlpha: 1 }))
  * composer.addPass(new THREEP.PixelationPass(4))
  *
  * composer.render()
  ###

  @create_texture_from_file: (map_image_file) ->
    throw "source file must be a PNG" unless map_image_file.toLowerCase().endsWith('.png')
    new Promise (done, error) ->
      png = new PNG
      stream = fs.createReadStream map_image_file
      stream.pipe png

      png.on 'parsed', () ->
        dataTexture = new THREE.DataTexture(png.data, png.width, png.height, THREE.RGBAFormat)
        dataTexture.needsUpdate = true
        done(dataTexture)


  @render_frame: (map_texture, degrees, target_width, target_height) ->
    new Promise (done, error) ->
      camera = new THREE.OrthographicCamera(-CAMERA_D, CAMERA_D, CAMERA_D, -CAMERA_D, -10, 1000)
      camera.position.set(10, -6, 10)
      camera.lookAt(0, 0, 0)

      scene = new THREE.Scene()
      scene.background = new THREE.Color(0x00ffff)

      planet_geometry = new THREE.SphereBufferGeometry(5, 32, 32)

      planet_material = new THREE.ShaderMaterial()
      planet_material.vertexShader = '''
      varying vec2 vUv;

      void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
      }
      '''
      planet_material.fragmentShader = '''
      uniform sampler2D dataTexture;
      varying vec2 vUv;
      void main() {
          gl_FragColor = texture2D(dataTexture, vUv);
      }
      '''
      planet_material.uniforms = dataTexture: { type: "t", value: map_texture }

      # new THREE.MeshBasicMaterial( { color: 0x000000, wireframe: false } )
      mesh = new THREE.Mesh(planet_geometry, planet_material)
      mesh.rotation.y = THREE.Math.degToRad(degrees)
      scene.add(mesh)

      renderer = new THREE.WebGLRenderer({
        antialias: true
        width: WIDTH
        height: HEIGHT
        canvas: { addEventListener: () -> }
        context: gl
      })
      # renderer.setPixelRatio(ASPECT)
      # renderer.setSize(WIDTH, HEIGHT)
      renderer.setDrawingBufferSize(PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, PlanetAnimationRenderer.ASPECT)

      renderTarget = new THREE.WebGLRenderTarget(PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, {
        minFilter: THREE.LinearFilter,
        magFilter: THREE.NearestFilter,
        format: THREE.RGBAFormat
      })

      renderer.render(scene, camera, renderTarget)

      pixels = new Uint8Array(4 * PlanetAnimationRenderer.WIDTH * PlanetAnimationRenderer.HEIGHT)
      renderer.readRenderTargetPixels(renderTarget, 0, 0, PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, pixels)
      done(pixels)

module.exports = PlanetAnimationRenderer
