
WIDTH = 512
HEIGHT = 512

CAMERA_D = 5.25

Jimp = require('jimp')
THREE = require('three')
THREEP = require('postprocessing')
gl = require('gl')(WIDTH, HEIGHT, {})

fs = require('fs')


class PlanetAnimationRenderer
  @WIDTH: WIDTH
  @HEIGHT: HEIGHT
  @ASPECT: @WIDTH / @HEIGHT

  @create_texture_from_file: (map_image_file) ->
    img = await Jimp.read(map_image_file)

    size = img.bitmap.width * img.bitmap.height
    rgbData = new Uint8Array(3 * size)
    for index in [0..size]
      if img.bitmap.data[index * 4 + 0] == 0 && img.bitmap.data[index * 4 + 1] == 0 && img.bitmap.data[index * 4 + 2] == 0
        # fill image border with water
        rgbData[index * 3 + 0] = 43
        rgbData[index * 3 + 1] = 84
        rgbData[index * 3 + 2] = 99
      else
        rgbData[index * 3 + 0] = img.bitmap.data[index * 4 + 0]
        rgbData[index * 3 + 1] = img.bitmap.data[index * 4 + 1]
        rgbData[index * 3 + 2] = img.bitmap.data[index * 4 + 2]

    dataTexture = new THREE.DataTexture(rgbData, img.bitmap.width, img.bitmap.height, THREE.RGBFormat)
    dataTexture.minFilter = THREE.LinearFilter
    dataTexture.needsUpdate = true
    dataTexture

  @render_frame: (map_texture, degrees, target_width, target_height) ->
    new Promise (done, error) ->
      warn_logger = console.warn
      console.warn = () -> {}

      camera = new THREE.OrthographicCamera(-CAMERA_D, CAMERA_D, CAMERA_D, -CAMERA_D, -10, 1000)
      camera.position.set(10, -6, 10)
      camera.lookAt(0, 0, 0)

      scene = new THREE.Scene()

      planet_geometry = new THREE.SphereBufferGeometry(5, 64, 64)
      planet_material = new THREE.MeshPhongMaterial({
        map: map_texture
        shininess: 10
      })

      mesh = new THREE.Mesh(planet_geometry, planet_material)
      mesh.rotation.y = THREE.Math.degToRad(degrees)
      scene.add(mesh)

      light = new THREE.DirectionalLight(0xffffff, 1)
      light.position.set(1000, -600, 1000)
      scene.add(light)
      scene.add(new THREE.AmbientLight(0x333333))

      renderer = new THREE.WebGLRenderer({
        antialias: true
        width: WIDTH
        height: HEIGHT
        canvas: { addEventListener: () -> }
        context: gl
      })
      renderer.setPixelRatio(PlanetAnimationRenderer.WIDTH / PlanetAnimationRenderer.HEIGHT)
      renderer.setDrawingBufferSize(PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, PlanetAnimationRenderer.ASPECT)

      renderTarget = new THREE.WebGLRenderTarget(PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, {
        minFilter: THREE.LinearFilter
        magFilter: THREE.NearestFilter
        format: THREE.RGBAFormat
      })

      renderer.setRenderTarget(renderTarget);
      renderer.render(scene, camera)

      pixels = new Uint8Array(4 * PlanetAnimationRenderer.WIDTH * PlanetAnimationRenderer.HEIGHT)
      renderer.readRenderTargetPixels(renderTarget, 0, 0, PlanetAnimationRenderer.WIDTH, PlanetAnimationRenderer.HEIGHT, pixels)

      console.warn = warn_logger
      done(pixels)

module.exports = PlanetAnimationRenderer
