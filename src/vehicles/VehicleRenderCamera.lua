-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 09|08|2023
-- @filename: VehicleRenderCamera.lua

local development = false -- if true, better quality but throws lua error (game works fine)

VehicleRenderCamera = {}

local VehicleRenderCamera_mt = Class(VehicleRenderCamera)

function VehicleRenderCamera.new(vehicle, customMt)
  local self = setmetatable({}, customMt or VehicleRenderCamera_mt)

  self.vehicle = vehicle

  return self
end

function VehicleRenderCamera:loadFromXML(xmlFile, key, savegame)
  self.cameraNode = xmlFile:getValue(key .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)

  if self.cameraNode == nil then
    Logging.xmlWarning(xmlFile, "Invalid camera node for camera '%s'!", key)

    return false
  end

  local name = xmlFile:getValue(key .. "#name", "$l10n_cameraSystem_default_camera_name")

  if name:sub(1, 6) == "$l10n_" then
    name = name:sub(7)

    if g_i18n:hasText(name) then
      name = g_i18n:getText(name)
    else
      name = g_i18n:getText(name, self.vehicle.customEnvironment)
    end
  end

  self.name = name
  self.fovY = xmlFile:getValue(key .. "#fov", 60)
  self.nearClip = xmlFile:getValue(key .. "#nearClip", 0.1)
  self.farClip = xmlFile:getValue(key .. "#farClip", 10000)
  self.translation = xmlFile:getValue(key .. "#translation", "0 0 0", true)
  self.rotation = xmlFile:getValue(key .. "#rotation", "0 0 0", true)
  self.activeFunc = xmlFile:getValue(key .. "#activeFunc")

  self:createCameraRender()

  return true
end

function VehicleRenderCamera:loadFromConfig(camera)
  self.cameraNode = camera.node

  if self.cameraNode == nil then
    Logging.xmlWarning(xmlFile, "Invalid camera node for camera node name '%s'!", camera.nodeName)

    return false
  end

  self.name = camera.name
  self.fovY = camera.fov
  self.nearClip = camera.nearClip
  self.farClip = camera.farClip
  self.translation = camera.translation
  self.rotation = camera.rotation
  self.activeFunc = camera.activeFunc

  self:createCameraRender()

  return true
end

function VehicleRenderCamera:createCameraRender()
  self.camera = createCamera(self.name, math.rad(self.fovY), self.nearClip, self.farClip)

  link(self.cameraNode, self.camera)

  setTranslation(self.camera, unpack(self.translation))
  setRotation(self.camera, unpack(self.rotation))

  local resolutionX = (g_screenWidth * .2) * 2
  local resolutionY = (g_screenHeight * .2) * 2
  local aspectRatio = resolutionX / resolutionY

  self.overlay = createRenderOverlay(self.camera, aspectRatio, resolutionX, resolutionY, true, development and 4294967295 or 4278255488, 4294967295, false, 5, false, 0, getCloudQuality())
end

function VehicleRenderCamera:update(dt)
  if self.overlay ~= 0 then
    updateRenderOverlay(self.overlay)
  end
end

function VehicleRenderCamera:draw(posX, posY, sizeX, sizeY)
  if self.overlay ~= 0 then
    renderOverlay(self.overlay, posX, posY, sizeX, sizeY)
  end
end

function VehicleRenderCamera:delete()
  if self.camera ~= nil then
    delete(self.camera)

    self.camera = nil
  end

  if self.overlay ~= 0 then
    delete(self.overlay)

    self.overlay = 0
  end
end

function VehicleRenderCamera.registerCameraXMLPaths(schema, basePath)
  schema:register(XMLValueType.STRING, basePath .. "#name", "Camera name")
  schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target camera node")
  schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Camera position")
  schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Camera rotation")
  schema:register(XMLValueType.FLOAT, basePath .. "#fov", "Camera field of view")
  schema:register(XMLValueType.FLOAT, basePath .. "#nearClip", "Camera near clip")
  schema:register(XMLValueType.FLOAT, basePath .. "#farClip", "Camera far clip")
  schema:register(XMLValueType.STRING, basePath .. "#activeFunc", "Camera activation function")
end