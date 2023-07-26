-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 03|03|2023
-- @filename: VehicleCameraSystem.lua

VehicleCameraSystem = {
  MOD_DIRECTORY = g_currentModDirectory,
  CAMERA_STATE = {
    OFF = 0,
    ON_ALWAYS = 1,
    ON_BACKWARD = 2
  },
  CONFIG_XML_KEY = "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(?).camera(?)"
}

source(VehicleCameraSystem.MOD_DIRECTORY .. "src/gui/hud/VehicleCameraSystemHUDExtension.lua")

VehicleHUDExtension.registerHUDExtension(VehicleCameraSystem, VehicleCameraSystemHUDExtension)

function VehicleCameraSystem.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function VehicleCameraSystem.initSpecialization()
  g_configurationManager:addConfigurationType("camera", g_i18n:getText("configuration_cameraSystem"), "cameraSystem", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)

  local schema = Vehicle.xmlSchema

  schema:setXMLSpecializationType("VehicleCameraSystem")
  schema:register(XMLValueType.STRING, VehicleCameraSystem.CONFIG_XML_KEY .. "#name", "Camera name", "$l10n_cameraSystem_default_camera_name")
  schema:register(XMLValueType.NODE_INDEX, VehicleCameraSystem.CONFIG_XML_KEY .. "#node", "Target node")
  schema:register(XMLValueType.VECTOR_TRANS, VehicleCameraSystem.CONFIG_XML_KEY .. "#translation", "Camera position")
  schema:register(XMLValueType.VECTOR_ROT, VehicleCameraSystem.CONFIG_XML_KEY .. "#rotation", "Camera rotation")
  schema:register(XMLValueType.FLOAT, VehicleCameraSystem.CONFIG_XML_KEY .. "#fov", "Camera field of view")

  ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(?)")

  schema:setXMLSpecializationType()
end

function VehicleCameraSystem.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "loadCameraFromXML", VehicleCameraSystem.loadCameraFromXML)
  SpecializationUtil.registerFunction(vehicleType, "loadCameraFromConfig", VehicleCameraSystem.loadCameraFromConfig)
  SpecializationUtil.registerFunction(vehicleType, "setCurrentCamera", VehicleCameraSystem.setCurrentCamera)
  SpecializationUtil.registerFunction(vehicleType, "setCameraSystemState", VehicleCameraSystem.setCameraSystemState)
  SpecializationUtil.registerFunction(vehicleType, "getIsCameraActive", VehicleCameraSystem.getIsCameraActive)
  SpecializationUtil.registerFunction(vehicleType, "getIsCameraSystemActive", VehicleCameraSystem.getIsCameraSystemActive)
end

function VehicleCameraSystem.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", VehicleCameraSystem)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdate", VehicleCameraSystem)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", VehicleCameraSystem)
  SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", VehicleCameraSystem)
  SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", VehicleCameraSystem)
end

function VehicleCameraSystem:onLoad(savegame)
  self.spec_vehicleCameraSystem = {}
  local spec = self.spec_vehicleCameraSystem

  local cameraConfigurationId = Utils.getNoNil(self.configurations.camera, 1)
  local configKey = string.format("vehicle.cameraSystem.cameraConfigurations.cameraConfiguration(%d)", cameraConfigurationId - 1)

  ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.cameraSystem.cameraConfigurations.cameraConfiguration", cameraConfigurationId, self.components, self)

  spec.cameras = {}

  local i = 0

  while true do
    local key = string.format("%s.camera(%d)", configKey, i)

    if not self.xmlFile:hasProperty(key) then
      break
    end

    local camera = {}

    if self:loadCameraFromXML(self.xmlFile, key, camera) then
      table.insert(spec.cameras, camera)

      camera.id = #spec.cameras
    end

    i = i + 1
  end

  if cameraConfigurationId > 1 and g_cameraSystem ~= nil then
    local cameraData = g_cameraSystem:getCameraSystemDefaultData(self.configFileName)

    if cameraData ~= nil then
      self:loadCameraFromConfig(cameraData.cameras, spec.cameras)
    end
  end

  spec.isEntered = false
  spec.isDrivable = true
  spec.isDrivingBackward = false

  if not SpecializationUtil.hasSpecialization(Drivable, self.specializations) then
    spec.isDrivable = false
  end

  spec.actionEvents = {}
  spec.currentCamera = nil
  spec.currentCameraId = 0
  spec.lastCameraState = nil
  spec.currentCameraState = VehicleCameraSystem.CAMERA_STATE.OFF
  spec.texts = {
    inputToggleChangeCamera = g_i18n:getText("action_changeCamera", self.customEnvironment),
    inputToggleCameraSystemOff = g_i18n:getText("action_cameraSystem_off", self.customEnvironment),
    inputToggleCameraSystemOnAlways = spec.isDrivable and g_i18n:getText("action_cameraSystem_on_always", self.customEnvironment) or g_i18n:getText("action_cameraSystem_on", self.customEnvironment),
    inputToggleCameraSystemOnBackward = g_i18n:getText("action_cameraSystem_on_backward", self.customEnvironment),
  }
  spec.hasCameras = #spec.cameras > 0

  if not spec.hasCameras then
    SpecializationUtil.removeEventListener(self, "onUpdate", VehicleCameraSystem)
    SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", VehicleCameraSystem)
    SpecializationUtil.removeEventListener(self, "onEnterVehicle", VehicleCameraSystem)
    SpecializationUtil.removeEventListener(self, "onLeaveVehicle", VehicleCameraSystem)
  elseif not spec.isDrivable then
    SpecializationUtil.removeEventListener(self, "onUpdate", VehicleCameraSystem)
  end
end

function VehicleCameraSystem:loadCameraFromXML(xmlFile, key, camera)
  camera.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

  if camera.node == nil then
    Logging.xmlWarning(self.xmlFile, "Missing 'node' for camera '%s'!", key)

    return false
  end

  local name = xmlFile:getValue(key .. "#name", "cameraSystem_default_camera_name")

  if name:sub(1, 6) == "$l10n_" then
    name = name:sub(7)
  end

  if (g_i18n:hasText(name)) then
    name = g_i18n:getText(name)
  else
    name = g_i18n:getText(name, self.customEnvironment)
  end

  camera.name = name
  camera.translation = xmlFile:getValue(key .. "#translation", "0 0 0", true)
  camera.rotation = xmlFile:getValue(key .. "#rotation", "0 0 0", true)
  camera.fov = math.rad(xmlFile:getValue(key .. "#fov", 60))

  return true
end

function VehicleCameraSystem:loadCameraFromConfig(cameraData, cameras)
  for i = 1, #cameraData do
    local camera = cameraData[i]

    if camera.nodeName ~= nil and self.i3dMappings[camera.nodeName] ~= nil then
      camera.node = self.i3dMappings[camera.nodeName].nodeId
    end

    table.insert(cameras, camera)

    camera.id = #cameras
  end
end

function VehicleCameraSystem:onUpdate(dt)
  local spec = self.spec_vehicleCameraSystem

  if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_BACKWARD then
    spec.isDrivingBackward = self:getIsDrivingBackward()
  end
end

function VehicleCameraSystem.updateActionEvents(self)
  local spec = self.spec_vehicleCameraSystem
  local actionEventToggleState = spec.actionEvents[InputAction.TOGGLE_CAMERA_SYSTEM]
  local isActive = false

  if actionEventToggleState ~= nil then
    if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.OFF then
      g_inputBinding:setActionEventText(actionEventToggleState.actionEventId, spec.texts.inputToggleCameraSystemOff)
    else
      isActive = true

      if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_ALWAYS then
        g_inputBinding:setActionEventText(actionEventToggleState.actionEventId, spec.texts.inputToggleCameraSystemOnAlways)
      elseif spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_BACKWARD then
        g_inputBinding:setActionEventText(actionEventToggleState.actionEventId, spec.texts.inputToggleCameraSystemOnBackward)
      end
    end

    local actionEventToggleCamera = spec.actionEvents[InputAction.TOGGLE_CAMERA_SYSTEM_CAMERA]

    if actionEventToggleCamera ~= nil then
      g_inputBinding:setActionEventActive(actionEventToggleCamera.actionEventId, isActive)
    end
  end
end

function VehicleCameraSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_vehicleCameraSystem

    self:clearActionEventsTable(spec.actionEvents)

    if isActiveForInputIgnoreSelection then
      local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CAMERA_SYSTEM, self, VehicleCameraSystem.actionEventToggleCameraSystem, false, true, false, true, nil)

      g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

      if #spec.cameras > 1 then
        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CAMERA_SYSTEM_CAMERA, self, VehicleCameraSystem.actionEventToggleCurrentCamera, false, true, false, true, nil)

        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        g_inputBinding:setActionEventText(actionEventId, spec.texts.inputToggleChangeCamera)
      end

      VehicleCameraSystem.updateActionEvents(self)
    end
  end
end

function VehicleCameraSystem:actionEventToggleCameraSystem(actionName, inputValue, callbackState, isAnalog)
  self:setCameraSystemState()
end

function VehicleCameraSystem:setCameraSystemState()
  local spec = self.spec_vehicleCameraSystem
  local state = nil

  spec.lastCameraState = spec.currentCameraState

  if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.OFF then
    state = VehicleCameraSystem.CAMERA_STATE.ON_ALWAYS
  elseif spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_ALWAYS then
    if spec.isDrivable then
      state = VehicleCameraSystem.CAMERA_STATE.ON_BACKWARD
    else
      state = VehicleCameraSystem.CAMERA_STATE.OFF
    end
  elseif spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_BACKWARD then
    state = VehicleCameraSystem.CAMERA_STATE.OFF
  end

  if spec.currentCameraState ~= state then
    spec.currentCameraState = state

    if self.isClient then
      VehicleCameraSystem.updateActionEvents(self)
    end
  end
end

function VehicleCameraSystem:actionEventToggleCurrentCamera(actionName, inputValue, callbackState, isAnalog)
  self:setCurrentCamera(self.spec_vehicleCameraSystem.currentCameraId + MathUtil.sign(inputValue))
end

function VehicleCameraSystem:setCurrentCamera(cameraId, forceUpdate)
  local spec = self.spec_vehicleCameraSystem

  if cameraId > #spec.cameras then
    cameraId = 1
  elseif cameraId < 1 then
    cameraId = #spec.cameras
  end

  cameraId = MathUtil.clamp(cameraId, 1, #spec.cameras)

  if cameraId ~= spec.currentCameraId or forceUpdate then
    spec.currentCameraId = cameraId

    spec.currentCamera = spec.cameras[spec.currentCameraId]
  end
end

function VehicleCameraSystem:onEnterVehicle(isControlling)
  local spec = self.spec_vehicleCameraSystem

  spec.isEntered = true

  self:setCurrentCamera(spec.currentCameraId ~= 0 and spec.currentCameraId or 1, true)
end

function VehicleCameraSystem:onLeaveVehicle()
  local spec = self.spec_vehicleCameraSystem

  spec.currentCamera = nil
end

function VehicleCameraSystem:getIsCameraActive()
  local spec = self.spec_vehicleCameraSystem

  if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_ALWAYS then
    return true
  end

  if spec.currentCameraState == VehicleCameraSystem.CAMERA_STATE.ON_BACKWARD then
    return spec.isDrivingBackward
  end

  return false
end

function VehicleCameraSystem:getIsCameraSystemActive()
  local spec = self.spec_vehicleCameraSystem

  if spec.currentCameraState ~= VehicleCameraSystem.CAMERA_STATE.OFF then
    return true
  end

  return false
end