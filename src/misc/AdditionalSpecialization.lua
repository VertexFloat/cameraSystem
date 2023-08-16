-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 09|08|2023
-- @filename: AdditionalSpecialization.lua

-- Changelog (1.0.0.1):
-- added adding multiple specializations
-- improved code

local modName = g_currentModName
local specializations = {
  enterable = {
    modName .. ".cameraSystem",
    modName .. ".cameraSystemEnterable"
  },
  attachable = {
    modName .. ".cameraSystem",
    modName .. ".cameraSystemAttachable"
  },
  attacherJoints = {
    modName .. ".cameraSystemAttacherJoints"
  }
}

local function finalizeTypes(self)
  if self.typeName == "vehicle" then
    for typeName, typeEntry in pairs(self:getTypes()) do
      for name, _ in pairs(typeEntry.specializationsByName) do
        for specName, specs in pairs(specializations) do
          if name == specName then
            for i = 1, #specs do
              if typeEntry.specializationsByName[specs[i]] == nil then
                self:addSpecialization(typeName, specs[i])
              end
            end
          end
        end
      end
    end
  end
end

TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, finalizeTypes)