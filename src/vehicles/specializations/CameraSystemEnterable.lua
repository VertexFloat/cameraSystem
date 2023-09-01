-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 09|08|2023
-- @filename: CameraSystemEnterable.lua

CameraSystemEnterable = {
  MOD_DIRECTORY = g_currentModDirectory
}

CameraSystemEnterable.STATE = {
  OFF = 0,
  ON = 1
}

source(CameraSystemEnterable.MOD_DIRECTORY .. "src/gui/hud/CameraSystemHUDExtension.lua")

VehicleHUDExtension.registerHUDExtension(CameraSystemEnterable, CameraSystemHUDExtension)

function CameraSystemEnterable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(CameraSystem, specializations)
end

function CameraSystemEnterable.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "addToolCameraSystemCameras", CameraSystemEnterable.addToolCameraSystemCameras)
  SpecializationUtil.registerFunction(vehicleType, "removeToolCameraSystemCameras", CameraSystemEnterable.removeToolCameraSystemCameras)
  SpecializationUtil.registerFunction(vehicleType, "setCameraSystemState", CameraSystemEnterable.setCameraSystemState)
  SpecializationUtil.registerFunction(vehicleType, "setActiveCameraSystemCameraIndex", CameraSystemEnterable.setActiveCameraSystemCameraIndex)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemActiveCameraIndex", CameraSystemEnterable.getCameraSystemActiveCameraIndex)
  SpecializationUtil.registerFunction(vehicleType, "getCameraSystemActiveCamera", CameraSystemEnterable.getCameraSystemActiveCamera)
  SpecializationUtil.registerFunction(vehicleType, "getIsCameraSystemActive", CameraSystemEnterable.getIsCameraSystemActive)
  SpecializationUtil.registerFunction(vehicleType, "getHasCameraSystem", CameraSystemEnterable.getHasCameraSystem)
end

function CameraSystemEnterable.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", CameraSystemEnterable)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CameraSystemEnterable)
  SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", CameraSystemEnterable)
end

function CameraSystemEnterable:onLoad(savegame)
  self.spec_cameraSystemEnterable = {}
  local spec = self.spec_cameraSystemEnterable

  spec.actionEvents = {}
  spec.texts = {
    inputToggleCameraSystemOn = g_i18n:getText("action_cameraSystem_on", self.customEnvironment),
    inputToggleCameraSystemOff = g_i18n:getText("action_cameraSystem_off", self.customEnvironment),
    inputToggleCameraSystemSwitchCamera = g_i18n:getText("action_cameraSystem_switchCamera", self.customEnvironment),
  }
  spec.camIndex = 1
  spec.hasCameras = self:getNumOfCameraSystemCameras() > 0
  spec.currentCameraSystemState = CameraSystemEnterable.STATE.OFF
  spec.isDirty = true

  self:setActiveCameraSystemCameraIndex(spec.camIndex)
end

function CameraSystemEnterable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_cameraSystemEnterable

    self:clearActionEventsTable(spec.actionEvents)

    if isActiveForInputIgnoreSelection and spec.hasCameras then
      local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CAMERA_SYSTEM, self, CameraSystemEnterable.actionEventCameraSystemState, false, true, false, true, nil)

      g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

      if self:getNumOfCameraSystemCameras() > 1 then
        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CAMERA_SYSTEM_CAMERA, self, CameraSystemEnterable.actionEventCameraSystemCameraSwitch, false, true, false, true, nil)

        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        g_inputBinding:setActionEventText(actionEventId, spec.texts.inputToggleCameraSystemSwitchCamera)
      end

      CameraSystemEnterable.updateActionEvents(self)
    end
  end
end

function CameraSystemEnterable:actionEventCameraSystemState(actionName, inputValue, callbackState, isAnalog)
  self:setCameraSystemState()
end

function CameraSystemEnterable:setCameraSystemState()
  local spec = self.spec_cameraSystemEnterable
  local state = nil

  if spec.currentCameraSystemState == CameraSystemEnterable.STATE.OFF then
    state = CameraSystemEnterable.STATE.ON
  else
    state = CameraSystemEnterable.STATE.OFF
  end

  if spec.currentCameraSystemState ~= state then
    spec.currentCameraSystemState = state

    if self.isClient then
      CameraSystemEnterable.updateActionEvents(self)
    end
  end
end

function CameraSystemEnterable:actionEventCameraSystemCameraSwitch(actionName, inputValue, callbackState, isAnalog)
  local spec = self.spec_cameraSystemEnterable

  self:setActiveCameraSystemCameraIndex(spec.camIndex + MathUtil.sign(inputValue))
end

function CameraSystemEnterable:setActiveCameraSystemCameraIndex(index)
  local spec = self.spec_cameraSystemEnterable
  local numCameras = self:getNumOfCameraSystemCameras()

  spec.camIndex = index

  if spec.camIndex <= 0 then
    spec.camIndex = numCameras
  end

  if numCameras < spec.camIndex then
    spec.camIndex = 1
  end

  spec.activeCamera = self.spec_cameraSystem.cameras[spec.camIndex]
end

function CameraSystemEnterable:addToolCameraSystemCameras(cameras)
  local spec = self.spec_cameraSystemEnterable
  local cameraSystemSpec = self.spec_cameraSystem

  for _, toolCamera in pairs(cameras) do
    table.insert(cameraSystemSpec.cameras, toolCamera)
  end

  cameraSystemSpec.numCameras = #cameraSystemSpec.cameras

  spec.hasCameras = self:getNumOfCameraSystemCameras() > 0

  if spec.hasCameras then
    self:setActiveCameraSystemCameraIndex(spec.camIndex)
  end
  -- we have to hard request actions update because some of implements have delay in function execution
  self:requestActionEventUpdate()
end

function CameraSystemEnterable:removeToolCameraSystemCameras(cameras)
  local spec = self.spec_cameraSystemEnterable
  local cameraSystemSpec = self.spec_cameraSystem
  local isToolCameraActive = false

  for i = #cameraSystemSpec.cameras, 1, -1 do
    local camera = cameraSystemSpec.cameras[i]

    for _, toolCamera in pairs(cameras) do
      if camera == toolCamera then
        table.remove(cameraSystemSpec.cameras, i)

        if spec.camIndex == i then
          isToolCameraActive = true
        end

        break
      end
    end
  end

  cameraSystemSpec.numCameras = #cameraSystemSpec.cameras

  spec.hasCameras = self:getNumOfCameraSystemCameras() > 0

  if isToolCameraActive then
    spec.camIndex = 1

    self:setActiveCameraSystemCameraIndex(spec.camIndex)
  end
end

function CameraSystemEnterable.updateActionEvents(self)
  local spec = self.spec_cameraSystemEnterable
  local actionEvent = spec.actionEvents[InputAction.TOGGLE_CAMERA_SYSTEM]
  local isActive = false

  if actionEvent ~= nil then
    if spec.currentCameraSystemState == CameraSystemEnterable.STATE.OFF then
      g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.inputToggleCameraSystemOff)
    else
      isActive = true

      g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.inputToggleCameraSystemOn)
    end
  end

  actionEvent = spec.actionEvents[InputAction.TOGGLE_CAMERA_SYSTEM_CAMERA]

  if actionEvent ~= nil then
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
  end
end

function CameraSystemEnterable:onEnterVehicle(isControlling)
  self.spec_cameraSystemEnterable.isDirty = true
end

function CameraSystemEnterable:getCameraSystemActiveCameraIndex()
  return self.spec_cameraSystemEnterable.camIndex
end

function CameraSystemEnterable:getCameraSystemActiveCamera()
  return self.spec_cameraSystemEnterable.activeCamera
end

function CameraSystemEnterable:getIsCameraSystemActive()
  return self.spec_cameraSystemEnterable.currentCameraSystemState ~= CameraSystemEnterable.STATE.OFF
end

function CameraSystemEnterable:getHasCameraSystem()
  return self.spec_cameraSystemEnterable.hasCameras
end