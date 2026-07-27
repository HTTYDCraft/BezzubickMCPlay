import JavaScriptEventLoop
import JavaScriptKit

#if os(WASI)

JavaScriptEventLoop.installGlobalExecutor()

// MARK: - Convenience helpers

let doc = JSObject.global.document
let win = JSObject.global.window

// MARK: - WebGL Liquid Glass (exact reference copy)

var glCtx: JSValue = .undefined
var shaderProg: JSValue = .undefined
var uniformLocs: [String: JSValue] = [:]
var lgCanvas: JSValue = .undefined
var shouldRender = false
var rafId: JSValue = .undefined
var rafClosure: JSClosure?

// Smooth mouse
var smoothMouseX = 0.5
var smoothMouseY = 0.5
var targetMouseX = 0.5
var targetMouseY = 0.5
let SMOOTHING = 0.05
let PI = 3.14159265359

var bgTexture: JSValue = .undefined
var texWidth = 512.0
var texHeight = 512.0
var textureClosures: [JSClosure] = []

let VERTEX_SHADER = """
#version 300 es
precision mediump float;
in vec3 aVertexPosition;
in vec2 aTextureCoord;
uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
uniform mat4 uTextureMatrix;
out vec2 vTextureCoord;
void main() {
  gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
  vTextureCoord = (uTextureMatrix * vec4(aTextureCoord, 0, 1)).xy;
}
"""

let FRAGMENT_SHADER = """
#version 300 es
precision mediump float;
in vec2 vTextureCoord;
uniform sampler2D uTexture;
uniform sampler2D uMaskTexture;
uniform vec2 uMousePos;
uniform vec2 uTMousePos;
uniform vec2 uResolution;
uniform vec2 uTextureResolution;
uniform float uRadius;
uniform float uDistort;
uniform float uDispersion;
uniform float uRotSpeed;
uniform float uShadowIntensity;
uniform float uShadowOffsetX;
uniform float uShadowOffsetY;
uniform float uShadowBlur;
uniform float uHighlightIntensity;
uniform float uHighlightSize;
uniform float uHighlightOffsetX;
uniform float uHighlightOffsetY;
out vec4 fragColor;
const float PI = 3.14159265359;
mat2 rot(float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, -s, s, c);
}
vec2 getAspectCorrectedUV(vec2 uv, out bool isOutOfBounds) {
  float textureAspect = uTextureResolution.x / uTextureResolution.y;
  float screenAspect = uResolution.x / uResolution.y;
  vec2 scale = vec2(1.0);
  if (textureAspect > screenAspect) {
    scale.y = textureAspect / screenAspect;
  } else {
    scale.x = screenAspect / textureAspect;
  }
  vec2 correctedUV = (uv - 0.5) * scale + 0.5;
  isOutOfBounds = correctedUV.x < 0.0 || correctedUV.x > 1.0 || correctedUV.y < 0.0 || correctedUV.y > 1.0;
  return correctedUV;
}
float sdCircle(vec2 uv, float r) {
  return length(uv) - r;
}
float getDist(vec2 uv) {
  float sd = sdCircle(uv, uRadius);
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 mp = uTMousePos * asp;
  float md = length(vTextureCoord * asp - mp);
  float fall = smoothstep(0.0, 0.8, md);
  float tweak = mix(0.02 / fall, 0.1 / fall, uDistort * sd);
  tweak = min(-tweak, 0.0);
  return sd - tweak;
}
float getShadow(vec2 uv, vec2 lightPos) {
  vec2 shadowOffset = vec2(uShadowOffsetX, uShadowOffsetY);
  vec2 shadowPos = uv - lightPos + shadowOffset;
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 st = shadowPos * asp;
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  float shadowDist = getDist(st);
  float shadow = 1.0 - smoothstep(-uShadowBlur, uShadowBlur, shadowDist);
  float distanceFromLight = length(uv - lightPos);
  float attenuation = 1.0 - smoothstep(0.0, 1.0, distanceFromLight);
  return shadow * uShadowIntensity * attenuation;
}
float getHighlight(vec2 uv, vec2 lightPos) {
  vec2 highlightOffset = vec2(uHighlightOffsetX, uHighlightOffsetY);
  vec2 highlightPos = uv - lightPos + highlightOffset;
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 st = highlightPos * asp;
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  float highlightRadius = uRadius * uHighlightSize;
  float highlightDist = sdCircle(st, highlightRadius);
  float highlight = 1.0 - smoothstep(-0.02, 0.02, highlightDist);
  float centerDist = length(st);
  float centerFalloff = 1.0 - smoothstep(0.0, highlightRadius * 0.8, centerDist);
  highlight *= centerFalloff;
  float distanceFromLight = length(uv - lightPos);
  float attenuation = 1.0 - smoothstep(0.0, 1.0, distanceFromLight);
  return highlight * uHighlightIntensity * attenuation;
}
vec4 refrakt(float sd, vec2 st, vec4 bg, vec2 originalUV) {
  vec2 offset = mix(vec2(0), normalize(st) / sd, length(st));
  float disp = uDispersion * 0.01;
  vec2 redOffset = offset * disp * 1.2;
  vec2 greenOffset = offset * disp * 1.0;
  vec2 blueOffset = offset * disp * 0.8;
  bool isOutOfBoundsR, isOutOfBoundsG, isOutOfBoundsB;
  vec2 redUV = originalUV + redOffset;
  vec2 greenUV = originalUV + greenOffset;
  vec2 blueUV = originalUV + blueOffset;
  vec2 aspectCorrectedRedUV = getAspectCorrectedUV(redUV, isOutOfBoundsR);
  vec2 aspectCorrectedGreenUV = getAspectCorrectedUV(greenUV, isOutOfBoundsG);
  vec2 aspectCorrectedBlueUV = getAspectCorrectedUV(blueUV, isOutOfBoundsB);
  float r, g, b;
  if (isOutOfBoundsR) { r = 0.8; } else { r = texture(uTexture, aspectCorrectedRedUV).r; }
  if (isOutOfBoundsG) { g = 0.8; } else { g = texture(uTexture, aspectCorrectedGreenUV).g; }
  if (isOutOfBoundsB) { b = 0.8; } else { b = texture(uTexture, aspectCorrectedBlueUV).b; }
  vec2 avgUV = originalUV + offset * disp;
  float shadow = getShadow(avgUV, uMousePos);
  vec4 refractedColor = vec4(r, g, b, 1.0);
  vec3 shadowColor = vec3(0.0, 0.0, 0.0);
  refractedColor.rgb = mix(refractedColor.rgb, shadowColor, shadow);
  float op = smoothstep(0.0, 0.0025, -sd);
  return mix(bg, refractedColor, op);
}
vec4 getEffect(vec2 st, vec4 bg, vec2 originalUV) {
  float eps = 0.0005;
  vec4 sum = vec4(0.0);
  sum += refrakt(getDist(st), st, bg, originalUV);
  sum += refrakt(getDist(st + vec2(eps, 0)), st + vec2(eps, 0), bg, originalUV);
  sum += refrakt(getDist(st - vec2(eps, 0)), st - vec2(eps, 0), bg, originalUV);
  sum += refrakt(getDist(st + vec2(0, eps)), st + vec2(0, eps), bg, originalUV);
  sum += refrakt(getDist(st - vec2(0, eps)), st - vec2(0, eps), bg, originalUV);
  return sum * 0.2;
}
void main() {
  vec2 uv = vTextureCoord;
  bool isOutOfBounds;
  vec2 aspectCorrectedUV = getAspectCorrectedUV(uv, isOutOfBounds);
  vec4 bg;
  if (isOutOfBounds) {
    bg = vec4(0.8, 0.8, 0.8, 1.0);
  } else {
    bg = texture(uTexture, aspectCorrectedUV);
  }
  float shadow = getShadow(uv, uMousePos);
  vec3 shadowColor = vec3(0.0, 0.0, 0.0);
  bg.rgb = mix(bg.rgb, shadowColor, shadow);
  vec2 st = uv - uMousePos;
  st *= vec2(uResolution.x / uResolution.y, 1.0);
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  vec4 color = getEffect(st, bg, uv);
  float highlight = getHighlight(uv, uMousePos);
  float exposure = 1.0 + highlight * 2.5;
  vec3 exposedColor = 1.0 - exp(-color.rgb * exposure);
  vec3 brightenedColor = color.rgb * (1.0 + highlight * 1.8);
  color.rgb = mix(exposedColor, brightenedColor, 0.3);
  vec3 warmTint = vec3(1.02, 1.01, 0.98);
  color.rgb *= mix(vec3(1.0), warmTint, highlight * 0.3);
  vec4 m = texture(uMaskTexture, uv);
  fragColor = color * (m.a * m.a);
}
"""

func compileShader(_ src: String, _ type: Int32) -> JSValue? {
  if glCtx.isUndefined { return nil }
  let s = glCtx.createShader(type)
  if s.isNull || s.isUndefined { return nil }
  _ = glCtx.shaderSource(s, src)
  _ = glCtx.compileShader(s)
  guard glCtx.getShaderParameter(s, glCtx.COMPILE_STATUS).boolean ?? false else { return nil }
  return s
}

func createProgram(_ vs: JSValue, _ fs: JSValue) -> JSValue? {
  let p = glCtx.createProgram()
  if p.isUndefined { return nil }
  _ = glCtx.attachShader(p, vs)
  _ = glCtx.attachShader(p, fs)
  _ = glCtx.linkProgram(p)
  guard glCtx.getProgramParameter(p, glCtx.LINK_STATUS).boolean ?? false else { return nil }
  return p
}

func resizeCanvas() {
  let dpr = win.devicePixelRatio.number ?? 1.0
  let ww = win.innerWidth.number ?? 1
  let wh = win.innerHeight.number ?? 1
  lgCanvas.style.width = .string("\(ww)px")
  lgCanvas.style.height = .string("\(wh)px")
  lgCanvas.width = .number(ww * dpr)
  lgCanvas.height = .number(wh * dpr)
  _ = glCtx.viewport(0, 0, ww * dpr, wh * dpr)
}

func createGradientCanvas() -> JSValue {
  let c = JSObject.global.document.createElement("canvas")
  _ = c.setAttribute("width", "512")
  _ = c.setAttribute("height", "512")
  let ctx = c.getContext("2d")
  let g = ctx.createLinearGradient(0, 0, 512, 512)
  _ = g.addColorStop(0, "#ff9a9e")
  _ = g.addColorStop(1, "#fad0c4")
  ctx.fillStyle = g
  _ = ctx.fillRect(0, 0, 512, 512)
  return c
}

func initWebGL() {
  let docObj = JSObject.global.document
  lgCanvas = docObj.createElement("canvas")
  let canvas = lgCanvas
  if canvas.isUndefined { return }
  canvas.style.cssText = .string("position:fixed;top:0;left:0;width:100vw;height:100vh;pointer-events:none;z-index:-1;display:block;")
  let body: JSValue = docObj.body
  _ = body.insertBefore(canvas, body.firstChild)
  glCtx = canvas.getContext("webgl2")
  if glCtx.isUndefined || glCtx.isNull { return }

  guard let vs = compileShader(VERTEX_SHADER, Int32(glCtx.VERTEX_SHADER.number ?? 0x8B31)),
        let fs = compileShader(FRAGMENT_SHADER, Int32(glCtx.FRAGMENT_SHADER.number ?? 0x8B30)) else { return }
  guard let prog = createProgram(vs, fs) else { return }
  shaderProg = prog
  _ = glCtx.useProgram(prog)
  for name in ["uMVMatrix", "uPMatrix", "uTextureMatrix", "uTexture", "uMaskTexture",
               "uMousePos", "uTMousePos", "uResolution", "uTextureResolution",
               "uRadius", "uDistort", "uDispersion", "uRotSpeed",
               "uShadowIntensity", "uShadowOffsetX", "uShadowOffsetY", "uShadowBlur",
               "uHighlightIntensity", "uHighlightSize", "uHighlightOffsetX", "uHighlightOffsetY"] {
    uniformLocs[name] = glCtx.getUniformLocation(prog, name)
  }

  // Identity matrices
  let id = [1.0,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
  if let u = uniformLocs["uMVMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uPMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uTextureMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uTexture"] { _ = glCtx.uniform1i(u, 0) }
  if let u = uniformLocs["uMaskTexture"] { _ = glCtx.uniform1i(u, 1) }

  setupGeometry()
  setupTextures()
  resizeCanvas()
}

func setupGeometry() {
  let vertData: [Double] = [-1,-1,0, 0,0,  1,-1,0, 1,0,  -1,1,0, 0,1,  1,1,0, 1,1]
  let buf = glCtx.createBuffer()
  _ = glCtx.bindBuffer(glCtx.ARRAY_BUFFER, buf)
  _ = glCtx.bufferData(glCtx.ARRAY_BUFFER, vertData.jsValue, glCtx.STATIC_DRAW)

  let posL = glCtx.getAttribLocation(shaderProg, "aVertexPosition").number ?? 0
  let uvL = glCtx.getAttribLocation(shaderProg, "aTextureCoord").number ?? 0
  _ = glCtx.enableVertexAttribArray(posL)
  _ = glCtx.vertexAttribPointer(posL, 3, glCtx.FLOAT, false, 5 * 4, 0)
  _ = glCtx.enableVertexAttribArray(uvL)
  _ = glCtx.vertexAttribPointer(uvL, 2, glCtx.FLOAT, false, 5 * 4, 3 * 4)
}

func createTexture(_ unit: Int32, _ source: JSValue) {
  _ = glCtx.activeTexture(0x84C0 + unit)
  let t = glCtx.createTexture()
  _ = glCtx.bindTexture(glCtx.TEXTURE_2D, t)
  _ = glCtx.pixelStorei(glCtx.UNPACK_FLIP_Y_WEBGL, 1)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MIN_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MAG_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_S, glCtx.CLAMP_TO_EDGE)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_T, glCtx.CLAMP_TO_EDGE)
  _ = glCtx.texImage2D(glCtx.TEXTURE_2D, 0, glCtx.RGBA, glCtx.RGBA, glCtx.UNSIGNED_BYTE, source)
}

func createMaskCanvas() -> JSValue {
  let c = JSObject.global.document.createElement("canvas")
  _ = c.setAttribute("width", "512")
  _ = c.setAttribute("height", "512")
  let ctx = c.getContext("2d")
  ctx.fillStyle = .string("#ffffff")
  _ = ctx.fillRect(0, 0, 512, 512)
  return c
}

func setupTextures() {
  // Create mask texture (unit 1)
  let maskCanvas = createMaskCanvas()
  createTexture(1, maskCanvas)

  // Try to load default background image (Unsplash), fallback to gradient
  let img = JSObject.global.document.createElement("img")
  img.crossOrigin = .string("anonymous")
  let loadHandler = JSClosure { _ in
    createTexture(0, img)
    texWidth = img.width.number ?? 512
    texHeight = img.height.number ?? 512
    textureClosures.removeAll()
    return .undefined
  }
  let errorHandler = JSClosure { _ in
    print("Failed to load default background image, falling back to gradient")
    let grad = createGradientCanvas()
    createTexture(0, grad)
    texWidth = 512
    texHeight = 512
    textureClosures.removeAll()
    return .undefined
  }
  textureClosures = [loadHandler, errorHandler]
  img.onload = .object(loadHandler)
  img.onerror = .object(errorHandler)
  img.src = .string("https://plus.unsplash.com/premium_photo-1677094766116-aa0f8742d36b?q=80&w=3087&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
}

func createUniform1f(_ name: String, _ val: Float) {
  if let u = uniformLocs[name] { _ = glCtx.uniform1f(u, val) }
}

func renderFrame() {
  if glCtx.isUndefined || shaderProg.isUndefined { return }

  _ = glCtx.clear(glCtx.COLOR_BUFFER_BIT)

  // Smooth mouse
  smoothMouseX += (targetMouseX - smoothMouseX) * SMOOTHING
  smoothMouseY += (targetMouseY - smoothMouseY) * SMOOTHING

  // Set uniforms
  let cw = lgCanvas.width.number ?? 1
  let ch = lgCanvas.height.number ?? 1
  if let u = uniformLocs["uResolution"] { _ = glCtx.uniform2f(u, Float(cw), Float(ch)) }
  if let u = uniformLocs["uTextureResolution"] { _ = glCtx.uniform2f(u, Float(texWidth), Float(texHeight)) }
  if let u = uniformLocs["uMousePos"] { _ = glCtx.uniform2f(u, Float(smoothMouseX), Float(smoothMouseY)) }
  if let u = uniformLocs["uTMousePos"] { _ = glCtx.uniform2f(u, Float(targetMouseX), Float(targetMouseY)) }

  createUniform1f("uRadius", 0.3)
  createUniform1f("uDistort", 3.5)
  createUniform1f("uDispersion", 1.0)
  createUniform1f("uRotSpeed", 1.0)
  createUniform1f("uShadowIntensity", 0.5)
  createUniform1f("uShadowOffsetX", 0.01)
  createUniform1f("uShadowOffsetY", 0.08)
  createUniform1f("uShadowBlur", 0.4)
  createUniform1f("uHighlightIntensity", 0.6)
  createUniform1f("uHighlightSize", 1.25)
  createUniform1f("uHighlightOffsetX", 0.01)
  createUniform1f("uHighlightOffsetY", 0.03)

  _ = glCtx.drawArrays(glCtx.TRIANGLE_STRIP, 0, 4)
}

func scheduleFrame() {
  guard shouldRender else { return }
  if rafClosure == nil {
    rafClosure = JSClosure { _ in
      renderFrame()
      scheduleFrame()
      return .undefined
    }
  }
  rafId = win.requestAnimationFrame(rafClosure!)
}

func startRendering() {
  guard !shouldRender else { return }
  shouldRender = true
  if glCtx.isUndefined { initWebGL() }
  scheduleFrame()
}

func stopRendering() { shouldRender = false }

func setupMouseTracking() {
  let fn = JSClosure { args in
    let e = args[0]
    targetMouseX = (e.clientX.number ?? 0) / (win.innerWidth.number ?? 1)
    targetMouseY = 1.0 - (e.clientY.number ?? 0) / (win.innerHeight.number ?? 1)
    return .undefined
  }
  smoothMouseX = targetMouseX
  smoothMouseY = targetMouseY
  _ = win.addEventListener("mousemove", fn)
  _ = win.addEventListener("touchmove", fn)

  let resizeFn = JSClosure { _ in resizeCanvas(); return .undefined }
  _ = win.addEventListener("resize", resizeFn)
}

func observeGlassState() {
  let body: JSValue = doc.body
  let ObsCtor = JSObject.global.MutationObserver.object!
  let cb = JSClosure { _ in
    let isGlass = (body.classList.contains("glass-dark").boolean ?? false) || (body.classList.contains("glass-light").boolean ?? false)
    if isGlass { startRendering() } else { stopRendering() }
    return .undefined
  }
  let observer = ObsCtor.new(cb)
  let config = JSObject()
  config["attributes"] = .boolean(true)
  config["attributeFilter"] = ["class"].jsValue
  _ = observer.observe!(body, config)
  let isGlass = (body.classList.contains("glass-dark").boolean ?? false) || (body.classList.contains("glass-light").boolean ?? false)
  if isGlass { startRendering() }
}

// MARK: - Entry Point

// All DOM logic (i18n, theming, calendar, data fetching) is owned by the
// inline JavaScript generated in Sources/BezzubickMCPlay/main.swift.
// This WASM client is a progressive enhancement that only renders the
// WebGL "Liquid Glass" background when a glass theme is active.

func boot() {
  setupMouseTracking()
  observeGlassState()
}

let bootClosure = JSClosure { _ in
  boot()
  return .undefined
}

if (doc.readyState.string ?? "complete") == "loading" {
  _ = doc.addEventListener("DOMContentLoaded", bootClosure)
} else {
  boot()
}

#endif
