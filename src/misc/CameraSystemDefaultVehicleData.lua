-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 24|03|2023
-- @filename: CameraSystemDefaultVehicleData.lua

CameraSystemDefaultVehicleData = {
  MOD_DIRECTORY = g_currentModDirectory,
  CONFIG_XML_KEY = "cameraSystemDefaultVehicleData.vehicles.vehicle(?).cameras.camera(?)",
  XML_SCHEMA = nil
}

CameraSystemDefaultVehicleData.CONFIG_XML_FILE = Utils.getFilename("data/CameraSystemDefaultVehicleData.xml", CameraSystemDefaultVehicleData.MOD_DIRECTORY)

local CameraSystemDefaultVehicleData_mt = Class(CameraSystemDefaultVehicleData)

function CameraSystemDefaultVehicleData.new(customMt)
  local self = setmetatable({}, customMt or CameraSystemDefaultVehicleData_mt)

  self.cameraData = {}
  self.isLoaded = false

  CameraSystemDefaultVehicleData.XML_SCHEMA = XMLSchema.new("cameraSystemDefaultVehicleData")

  self:registerXMLPaths(CameraSystemDefaultVehicleData.XML_SCHEMA)

  return self
end

function CameraSystemDefaultVehicleData:loadFromXMLFile()
  if not self.isLoaded then
    self:loadDefualtVehicleCameraSystemData()
  end
end

function CameraSystemDefaultVehicleData:loadDefualtVehicleCameraSystemData()
  local xmlFile = XMLFile.load("CameraSystemDefaultVehicleDataXML", CameraSystemDefaultVehicleData.CONFIG_XML_FILE, CameraSystemDefaultVehicleData.XML_SCHEMA)

  if xmlFile ~= nil then
    self.cameraData = {}

    xmlFile:iterate("cameraSystemDefaultVehicleData.vehicles.vehicle", function (_, key)
      local vehicle = {
        xmlFilename = xmlFile:getValue(key .. "#xmlFilename"),
        price = xmlFile:getValue(key .. "#price")
      }

      if vehicle.xmlFilename ~= nil then
        vehicle.cameras = {}

        xmlFile:iterate(key .. ".cameras.camera", function (_, cameraKey)
          local camera = {}

          camera.nodeName = xmlFile:getValue(cameraKey .. "#nodeName")

          if camera.nodeName == nil then
            Logging.xmlWarning(self.xmlFile, "Missing 'nodeName' for camera '%s'!", cameraKey)

            return false
          end

          camera.name = g_i18n:getText(xmlFile:getValue(cameraKey .. "#name", "cameraSystem_default_camera_name"))
          camera.translation = xmlFile:getValue(cameraKey .. "#translation", "0 0 0", true)
          camera.rotation = xmlFile:getValue(cameraKey .. "#rotation", "0 0 0", true)
          camera.fov = math.rad(xmlFile:getValue(cameraKey .. "#fov", 60))

          table.insert(vehicle.cameras, camera)
        end)
      end

      table.insert(self.cameraData, vehicle)
    end)

    xmlFile:delete()
  end

  self.isLoaded = true
end

function CameraSystemDefaultVehicleData:overwriteGameFunctions(cameraSystem)
  cameraSystem:overwriteGameFunction(StoreItemUtil, "getConfigurationsFromXML", function (superFunc, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
    local configurations, defaultConfigurationIds = superFunc(xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
    local vehicleData = self:getCameraSystemDefaultData(xmlFile.filename)

    if not self.isLoaded then
      self:loadDefualtVehicleCameraSystemData()
    end

    if vehicleData ~= nil then
      if configurations == nil then
        configurations = {}
      end

      if defaultConfigurationIds == nil then
        defaultConfigurationIds = {}
      end

      configurations.camera = {
        {
          isDefault = true,
          saveId = "1",
          isSelectable = true,
          index = 1,
          dailyUpkeep = 0,
          price = 0,
          name = g_i18n:getText("configuration_valueNo"),
          nameCompareParams = {}
        },
        {
          isDefault = false,
          saveId = "2",
          isSelectable = true,
          index = 2,
          dailyUpkeep = 0,
          name = g_i18n:getText("configuration_valueYes"),
          price = vehicleData.price,
          nameCompareParams = {}
        }
      }
    end

    return configurations, defaultConfigurationIds
  end)
  cameraSystem:overwriteGameFunction(FSBaseMission, "consoleCommandReloadVehicle", function (superFunc, mission, resetVehicle, radius)
    self:loadDefualtVehicleCameraSystemData()

    return superFunc(mission, resetVehicle, radius)
  end)
end

function CameraSystemDefaultVehicleData:getCameraSystemDefaultData(configFilename)
  for i = 1, #self.cameraData do
    local vehicleData = self.cameraData[i]

    if configFilename:endsWith(vehicleData.xmlFilename) then
      return vehicleData
    end
  end
end

function CameraSystemDefaultVehicleData:delete()
  self.cameraData = {}
end

function CameraSystemDefaultVehicleData:registerXMLPaths(schema)
  schema:register(XMLValueType.STRING, "cameraSystemDefaultVehicleData.vehicles.vehicle(?)#xmlFilename", "Vehicle filename")
  schema:register(XMLValueType.STRING, "cameraSystemDefaultVehicleData.vehicles.vehicle(?)#price", "Vehicle configuration price")

  schema:register(XMLValueType.L10N_STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#name", "Camera name", "cameraSystem_default_camera_name")
  schema:register(XMLValueType.STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#nodeName", "Target node name")
  schema:register(XMLValueType.VECTOR_TRANS, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#translation", "Camera position")
  schema:register(XMLValueType.VECTOR_ROT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#rotation", "Camera rotation")
  schema:register(XMLValueType.FLOAT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#fov", "Camera field of view")
end