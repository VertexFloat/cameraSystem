-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 09|08|2023
-- @filename: CameraSystemAttacherJoints.lua

CameraSystemAttacherJoints = {}

function CameraSystemAttacherJoints.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end

function CameraSystemAttacherJoints.registerOverwrittenFunctions(vehicleType)
  SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddCameraSystemCameras", CameraSystemAttacherJoints.attachableAddCameraSystemCameras)
  SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveCameraSystemCameras", CameraSystemAttacherJoints.attachableRemoveCameraSystemCameras)
end

function CameraSystemAttacherJoints:attachableAddCameraSystemCameras(superFunc)
  local spec = self.spec_attacherJoints

  superFunc(self)

  for _, implement in pairs(spec.attachedImplements) do
    local object = implement.object

    if object ~= nil and object.attachableAddCameraSystemCameras ~= nil then
      object:attachableAddCameraSystemCameras()
    end
  end
end

function CameraSystemAttacherJoints:attachableRemoveCameraSystemCameras(superFunc)
  local spec = self.spec_attacherJoints

  superFunc(self)

  for _, implement in pairs(spec.attachedImplements) do
    local object = implement.object

    if object ~= nil and object.attachableRemoveCameraSystemCameras ~= nil then
      object:attachableRemoveCameraSystemCameras()
    end
  end
end