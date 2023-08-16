-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 09|08|2023
-- @filename: CameraSystemAttachable.lua

CameraSystemAttachable = {}

function CameraSystemAttachable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Attachable, specializations) and SpecializationUtil.hasSpecialization(CameraSystem, specializations)
end

function CameraSystemAttachable.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "attachableAddCameraSystemCameras", CameraSystemAttachable.attachableAddCameraSystemCameras)
  SpecializationUtil.registerFunction(vehicleType, "attachableRemoveCameraSystemCameras", CameraSystemAttachable.attachableRemoveCameraSystemCameras)
end

function CameraSystemAttachable.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", CameraSystemAttachable)
  SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", CameraSystemAttachable)
end

function CameraSystemAttachable:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
  self:attachableAddCameraSystemCameras()
end

function CameraSystemAttachable:attachableAddCameraSystemCameras()
  local spec = self.spec_cameraSystem

  if #spec.cameras > 0 then
    local rootAttacherVehicle = self.rootVehicle

    if rootAttacherVehicle ~= nil and rootAttacherVehicle.addToolCameraSystemCameras ~= nil then
      rootAttacherVehicle:addToolCameraSystemCameras(spec.cameras)
    end
  end
end

function CameraSystemAttachable:onPostDetach()
  self:attachableRemoveCameraSystemCameras()
end

function CameraSystemAttachable:attachableRemoveCameraSystemCameras()
  local spec = self.spec_cameraSystem

  if #spec.cameras > 0 then
    local rootAttacherVehicle = self.rootVehicle

    if rootAttacherVehicle ~= nil and rootAttacherVehicle.removeToolCameraSystemCameras ~= nil then
      rootAttacherVehicle:removeToolCameraSystemCameras(spec.cameras)
    end
  end
end