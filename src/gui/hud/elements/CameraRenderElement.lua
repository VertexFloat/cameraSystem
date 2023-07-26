-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 06|06|2022
-- @filename: CameraRenderElement.lua

local development = false -- if true, better quality but throws lua error (game works fine)

CameraRenderElement = {
  SCENE_PATH = g_currentModDirectory .. "data/camera.i3d"
}

local CameraRenderElement_mt = Class(CameraRenderElement)

function CameraRenderElement.new(size, customMt)
  local self = setmetatable({}, customMt or CameraRenderElement_mt)

  self.size = size
  self.camera = nil
  self.cameraNode = "0|0"
  self.linkNode = nil
  self.overlay = 0

  self:createScene()

  return self
end

function CameraRenderElement:createScene()
  self:setScene(CameraRenderElement.SCENE_PATH)
end

function CameraRenderElement:setScene(filename)
  if self.scene ~= nil then
    delete(self.scene)

    self.scene = nil
  end

  if self.loadingRequestId ~= nil then
    g_i3DManager:cancelStreamI3DFile(self.loadingRequestId)

    self.loadingRequestId = nil
  end

  self.isLoading = true
  self.loadingRequestId = g_i3DManager:loadI3DFileAsync(filename, false, false, CameraRenderElement.setSceneFinished, self, nil)
end

function CameraRenderElement:setSceneFinished(node, failedReason, args)
  self.isLoading = false
  self.loadingRequestId = nil

  if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
    Logging.error("Failed to load camera scene from '%s'", CameraRenderElement.SCENE_PATH)
  end

  if failedReason == LoadI3DFailedReason.NONE then
    self.scene = node

    self:createOverlay()
  elseif node ~= 0 then
    delete(node)
  end
end

function CameraRenderElement:createOverlay()
  if self.overlay ~= 0 then
    delete(self.overlay)

    self.overlay = 0
  end

  local resolutionX = math.ceil(g_screenWidth * self.size[1]) * 2
  local resolutionY = math.ceil(g_screenHeight * self.size[2]) * 2
  local aspectRatio = resolutionX / resolutionY

  self.camera = I3DUtil.indexToObject(self.scene, self.cameraNode)

  if self.camera == nil then
    Logging.error("Could not find camera node '%s' in scene", self.cameraNode)
  else
    self.overlay = createRenderOverlay(self.camera, aspectRatio, resolutionX, resolutionY, true, development and 4294967295 or 4278255488, 4294967295, nil, nil, nil, nil, getViewDistanceCoeff())
  end
end

function CameraRenderElement:link(camera)
  if self.scene then
    self:reset()

    if camera.node == nil or camera.node == 0 or not entityExists(camera.node) then
      camera.node = getRootNode()
    end

    link(camera.node, self.scene)

    setTranslation(self.scene, unpack(camera.translation))
    setRotation(self.scene, unpack(camera.rotation))

    if self.camera ~= nil then
      setFovY(self.camera, camera.fov)
    end

    self.linkNode = camera.node
  end
end

function CameraRenderElement:reset()
  unlink(self.scene)

  setTranslation(self.scene, 0, 0, 0)
  setRotation(self.scene, 0, 0, 0)
  setFovY(self.camera, math.rad(60))

  self.linkNode = nil
end

function CameraRenderElement:update(dt)
  if self.overlay ~= 0 then
    updateRenderOverlay(self.overlay)
  end
end

function CameraRenderElement:draw(posX, posY)
  if not self.isLoading and self.overlay ~= 0 then
    local sizeX = self.size[1]
    local sizeY = self.size[2]

    setOverlayUVs(self.overlay, 0, 0, 0, 1, 1, 0, 1, 1)
    renderOverlay(self.overlay, posX, posY, sizeX, sizeY)
  end
end

function CameraRenderElement:destroyScene()
  if self.loadingRequestId ~= nil then
    g_i3DManager:cancelStreamI3DFile(self.loadingRequestId)

    self.loadingRequestId = nil
  end

  if self.overlay ~= 0 then
    delete(self.overlay)

    self.overlay = 0
  end

  if self.scene and entityExists(self.scene) then
    delete(self.scene)

    self.scene = nil
  end

  if self.linkNode then
    self.linkNode = nil
  end
end

function CameraRenderElement:delete()
  self:destroyScene()
end