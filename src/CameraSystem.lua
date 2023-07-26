-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 03|03|2023
-- @filename: CameraSystem.lua

CameraSystem = {
  MOD_DIRECTORY = g_currentModDirectory
}

source(CameraSystem.MOD_DIRECTORY .. "src/misc/AdditionalSpecialization.lua")
source(CameraSystem.MOD_DIRECTORY .. "src/misc/CameraSystemDefaultVehicleData.lua")
source(CameraSystem.MOD_DIRECTORY .. "src/gui/hud/CameraSystemInputHelpDisplayExtension.lua")

local CameraSystem_mt = Class(CameraSystem)

function CameraSystem.new(customMt)
  local self = setmetatable({}, customMt or CameraSystem_mt)

  self.isPrecisionFarming = false

  self.inputHelpDisplayExtension = CameraSystemInputHelpDisplayExtension.new()
  self.cameraSystemDefaultVehicleData = CameraSystemDefaultVehicleData.new()

  return self
end

function CameraSystem:initialize()
  self.inputHelpDisplayExtension:overwriteGameFunctions(self)
  self.cameraSystemDefaultVehicleData:overwriteGameFunctions(self)
end

function CameraSystem:loadMap(filename)
  self.cameraSystemDefaultVehicleData:loadFromXMLFile()
end

function CameraSystem:getCameraSystemDefaultData(configFileName)
  return self.cameraSystemDefaultVehicleData:getCameraSystemDefaultData(configFileName)
end

function CameraSystem:getIsPrecisionFarming()
  return self.isPrecisionFarming
end

function CameraSystem:overwriteGameFunction(object, funcName, newFunc)
  if object == nil then
    return
  end

  local oldFunc = object[funcName]

  if oldFunc ~= nil then
    object[funcName] = function (...)
      return newFunc(oldFunc, ...)
    end
  end
end

function CameraSystem:deleteMap()
  self.cameraSystemDefaultVehicleData:delete()
end

g_cameraSystem = CameraSystem.new()

addModEventListener(g_cameraSystem)

local function validateTypes(self)
  if self.typeName == "vehicle" then
    g_cameraSystem:initialize()

    if g_modIsLoaded.FS22_precisionFarming then
      g_cameraSystem.isPrecisionFarming = true
    end
  end
end

TypeManager.validateTypes = Utils.appendedFunction(TypeManager.validateTypes, validateTypes)