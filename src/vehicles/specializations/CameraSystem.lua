-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 09|08|2023
-- @filename: CameraSystem.lua

CameraSystem = {}

function CameraSystem.prerequisitesPresent(specializations)
  return true
end

function CameraSystem.initSpecialization()
  g_configurationManager:addConfigurationType("camera", g_i18n:getText("configuration_cameraSystem"), "cameraSystem", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
  local schema = Vehicle.xmlSchema

  schema:setXMLSpecializationType("CameraSystem")
  VehicleRenderCamera.registerCameraXMLPaths(schema, "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(?).camera(?)")
  ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(?)")
  schema:setXMLSpecializationType()
end

function CameraSystem.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "loadCameraFromXML", CameraSystem.loadCameraFromXML)
  SpecializationUtil.registerFunction(vehicleType, "loadCameraFromConfig", CameraSystem.loadCameraFromConfig)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemIsReverse", CameraSystem.getCameraSystemIsReverse)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemIsLowered", CameraSystem.getCameraSystemIsLowered)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemIsUnfolded", CameraSystem.getCameraSystemIsUnfolded)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemIsPipeUnfolded", CameraSystem.getCameraSystemIsPipeUnfolded)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemIsCameraActive", CameraSystem.getCameraSystemIsCameraActive)
  SpecializationUtil.registerFunction(vehicleType, "getNumOfCameraSystemCameras", CameraSystem.getNumOfCameraSystemCameras)
end

function CameraSystem.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", CameraSystem)
  SpecializationUtil.registerEventListener(vehicleType, "onDelete", CameraSystem)
end

function CameraSystem:onLoad(savegame)
  self.spec_cameraSystem = {}
  local spec = self.spec_cameraSystem

  local cameraConfigurationId = Utils.getNoNil(self.configurations.camera, 1)
  local configKey = string.format("vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(%d)", cameraConfigurationId - 1)

  ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration", cameraConfigurationId, self.components, self)

  self:loadCameraFromXML(self.xmlFile, configKey, savegame)

  if cameraConfigurationId > 1 and g_cameraSystem ~= nil then
    local cameraData = g_cameraSystem:getCameraSystemDefaultData(self.configFileName)

    if cameraData ~= nil then
      self:loadCameraFromConfig(cameraData.cameras)
    end
  end
end

function CameraSystem:loadCameraFromXML(xmlFile, configKey, savegame)
  local spec = self.spec_cameraSystem

  spec.cameras = {}
  local i = 0

  while true do
    local key = string.format("%s.camera(%d)", configKey, i)

    if not xmlFile:hasProperty(key) then
      break
    end

    local camera = VehicleRenderCamera.new(self)

    if camera:loadFromXML(xmlFile, key, savegame) then
      table.insert(spec.cameras, camera)
    end

    i = i + 1
  end

  spec.numCameras = #spec.cameras
end

function CameraSystem:loadCameraFromConfig(camerasData)
  local spec = self.spec_cameraSystem

  spec.cameras = {}

  for i = 1, #camerasData do
    local cameraData = camerasData[i]

    if cameraData.nodeName ~= nil and self.i3dMappings[cameraData.nodeName] ~= nil then
      cameraData.node = self.i3dMappings[cameraData.nodeName].nodeId
    end

    local camera = VehicleRenderCamera.new(self)

    if camera:loadFromConfig(cameraData) then
      table.insert(spec.cameras, camera)
    end
  end

  spec.numCameras = #spec.cameras
end

function CameraSystem:getCameraSystemIsReverse()
  local infoText = g_i18n:getText("cameraSystem_camera_info_reverse")

  if SpecializationUtil.hasSpecialization(Drivable, self.specializations) then
    return self:getIsDrivingBackward(), infoText
  end

  return true, infoText
end

function CameraSystem:getCameraSystemIsLowered()
  local infoText = string.format(g_i18n:getText("cameraSystem_camera_info_lowered"), self:getName())

  if SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
    return self:getIsLowered(), infoText
  end

  return true, infoText
end

function CameraSystem:getCameraSystemIsUnfolded()
  local infoText = string.format(g_i18n:getText("cameraSystem_camera_info_unfolded"), self:getName())

  if SpecializationUtil.hasSpecialization(Foldable, self.specializations) then
    return self:getIsUnfolded(), infoText
  end

  return true, infoText
end

function CameraSystem:getCameraSystemIsPipeUnfolded()
  local infoText = g_i18n:getText("cameraSystem_camera_info_pipeUnfolded")

  if SpecializationUtil.hasSpecialization(Pipe, self.specializations) then
    return self.spec_pipe.unloadingStates[self.spec_pipe.currentState] == true, infoText
  end

  return true, infoText
end

function CameraSystem:getCameraSystemIsCameraActive(activeCamera)
  local spec = self.spec_cameraSystem

  for i = 1, #spec.cameras do
    local camera = spec.cameras[i]

    if camera == activeCamera then
      local func = self[camera.activeFunc]

      if func ~= nil then
        return func(camera.vehicle)
      end

      break
    end
  end

  return true
end

function CameraSystem:getNumOfCameraSystemCameras()
  return self.spec_cameraSystem.numCameras
end

function CameraSystem:onDelete()
  local spec = self.spec_cameraSystem

  if spec.cameras ~= nil then
    for _, camera in pairs(spec.cameras) do
      camera:delete()
    end
  end
end