-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 12|08|2023
-- @filename: CameraSystemDefaultVehicleData.lua

-- Changelog (1.0.0.1):
-- added option to add cameras to mod/internalMod/dlc vehicles

CameraSystemDefaultVehicleData = {
  MOD_NAME = g_currentModName,
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
        xmlFilename = self:getVehicleXmlFilenamePath(xmlFile:getValue(key .. "#xmlFilename")),
        price = xmlFile:getValue(key .. "#price", 500)
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

          local visibilityNodeName = xmlFile:getValue(cameraKey .. "#visibilityNodeName")

          if visibilityNodeName ~= "" then
            camera.visibilityNodeName = visibilityNodeName
          end

          camera.name = xmlFile:getValue(cameraKey .. "#name", "ui_cameraSystem_nameDefault", CameraSystemDefaultVehicleData.MOD_NAME)
          camera.translation = xmlFile:getValue(cameraKey .. "#translation", "0 0 0", true)
          camera.rotation = xmlFile:getValue(cameraKey .. "#rotation", "0 0 0", true)
          camera.fov = xmlFile:getValue(cameraKey .. "#fov", 60)
          camera.nearClip = xmlFile:getValue(cameraKey .. "#nearClip", 0.01)
          camera.farClip = xmlFile:getValue(cameraKey .. "#farClip", 10000)
          camera.activeFunc = xmlFile:getValue(cameraKey .. "#activeFunc")

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

function CameraSystemDefaultVehicleData:getVehicleXmlFilenamePath(xmlFilename)
  if xmlFilename:sub(1, 3) == "mod" then
    xmlFilename = g_modsDirectory .. xmlFilename:sub(5)
  end

  if xmlFilename:sub(1, 3) == "dlc" then
    xmlFilename = getAppBasePath() .. "pdlc/" .. xmlFilename:sub(5)
  end
  -- needs to be tested
  if xmlFilename:sub(1, 8) == "internal" then
    xmlFilename = g_internalModsDirectory .. xmlFilename:sub(10)
  end

  return xmlFilename
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

  schema:register(XMLValueType.L10N_STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#name", "Camera name")
  schema:register(XMLValueType.STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#nodeName", "Target node name")
  schema:register(XMLValueType.STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#visibilityNodeName", "Target node name that visibility is needed")
  schema:register(XMLValueType.VECTOR_TRANS, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#translation", "Camera position")
  schema:register(XMLValueType.VECTOR_ROT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#rotation", "Camera rotation")
  schema:register(XMLValueType.FLOAT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#fov", "Camera field of view")
  schema:register(XMLValueType.FLOAT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#nearClip", "Camera near clip")
  schema:register(XMLValueType.FLOAT, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#farClip", "Camera far clip")
  schema:register(XMLValueType.STRING, CameraSystemDefaultVehicleData.CONFIG_XML_KEY .. "#activeFunc", "Camera activation function")
end