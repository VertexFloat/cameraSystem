-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 03|03|2023
-- @filename: VehicleCameraSystemHUDExtension.lua

VehicleCameraSystemHUDExtension = {
  MOD_DIRECTORY = g_currentModDirectory
}

VehicleCameraSystemHUDExtension.HUD_ELEMENTS = VehicleCameraSystemHUDExtension.MOD_DIRECTORY .. "data/menu/hud/hud_elements.png"

source(VehicleCameraSystemHUDExtension.MOD_DIRECTORY .. "src/gui/hud/elements/CameraRenderElement.lua")

local VehicleCameraSystemHUDExtension_mt = Class(VehicleCameraSystemHUDExtension, VehicleHUDExtension)

function VehicleCameraSystemHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
  local self = VehicleHUDExtension.new(VehicleCameraSystemHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)

  self.vehicleCameraSystem = vehicle.spec_vehicleCameraSystem

  _, self.displayHeight = getNormalizedScreenValues(0, ((InputHelpDisplay.WIDTH / 2) + 4) * uiScale)
  self.cameraRenderWidth, self.cameraRenderHeight = getNormalizedScreenValues((InputHelpDisplay.WIDTH - 2) * uiScale, ((InputHelpDisplay.WIDTH / 2) + 2) * uiScale)
  self.cameraNameTextOffset, self.cameraNameTextHeight = getNormalizedScreenValues(13 * uiScale, 20 * uiScale)
  self.cameraNameMaxTextWidth, _ = getNormalizedScreenValues(300 * uiScale, 0)
  self.cameraIdTextOffset, self.cameraIdTextHeight = getNormalizedScreenValues(2 * uiScale, 16 * uiScale)
  self.statusOverlayOffsetX, _ = getNormalizedScreenValues(3 * uiScale, 0)
  _, self.errorTextHeight = getNormalizedScreenValues(0, 22 * uiScale)
  self.inputHelpDisplayOffsetX, _ = getNormalizedScreenValues(InputHelpDisplay.POSITION.AXIS_ICON[1] * uiScale, 0)

  local width, height = getNormalizedScreenValues(30 * uiScale, 22 * uiScale)

  self.statusOverlay = Overlay.new(VehicleCameraSystemHUDExtension.HUD_ELEMENTS, 0, 0, width, height)
  self.statusOverlay:setUVs(GuiUtils.getUVs(VehicleCameraSystemHUDExtension.UV.STATUS))
  self.statusOverlay:setColor(unpack(VehicleCameraSystemHUDExtension.COLOR.STATUS.OFF))

  self:addComponentForCleanup(self.statusOverlay)

  width, height = getNormalizedScreenValues(256 * uiScale, 128 * uiScale)

  local brand = vehicle.brand.imageShopOverview or g_brandManager:getBrandByIndex(Brand.LIZARD).imageShopOverview

  self.brandOverlay = Overlay.new(brand, 0, 0, width, height)
  self.brandOverlay:setColor(nil, nil, nil, 1)

  self:addComponentForCleanup(self.brandOverlay)

  self.texts = {
    id = g_i18n:getText("cameraSystem_camera_id"),
    error = g_i18n:getText("cameraSystem_camera_error")
  }

  self.brandAnimation = TweenSequence.NO_SEQUENCE
  self.statusAnimation = TweenSequence.NO_SEQUENCE

  self.isSplashScreen = self.vehicleCameraSystem.isEntered
  self.isSplashScreenAnimation = true

  self.isCameraRenderable = false

  if self.vehicleCameraSystem.hasCameras then
    self.cameraRender = CameraRenderElement.new({self.cameraRenderWidth, self.cameraRenderHeight})
  end

  self:createAnimations()

  return self
end

function VehicleCameraSystemHUDExtension:createAnimations()
  local brandAnimation = TweenSequence.new(self)

  brandAnimation:addInterval(VehicleCameraSystemHUDExtension.ANIMATION.SHOW_TIME.FADE)
  brandAnimation:addTween(MultiValueTween.new(self.setBrandAlphaChannel, VehicleCameraSystemHUDExtension.COLOR.BRAND.VISIBLE, VehicleCameraSystemHUDExtension.COLOR.BRAND.INVISIBLE, VehicleCameraSystemHUDExtension.ANIMATION.TIME.FADE))

  self.brandAnimation = brandAnimation

  local statusAnimation = TweenSequence.new(self)

  statusAnimation:addTween(MultiValueTween.new(self.setStatusColorChannels, VehicleCameraSystemHUDExtension.COLOR.STATUS.OFF, VehicleCameraSystemHUDExtension.COLOR.STATUS.ON, VehicleCameraSystemHUDExtension.ANIMATION.TIME.BLINK))
  statusAnimation:addInterval(VehicleCameraSystemHUDExtension.ANIMATION.SHOW_TIME.BLINK)
  statusAnimation:addTween(MultiValueTween.new(self.setStatusColorChannels, VehicleCameraSystemHUDExtension.COLOR.STATUS.ON, VehicleCameraSystemHUDExtension.COLOR.STATUS.OFF, VehicleCameraSystemHUDExtension.ANIMATION.TIME.BLINK))
  statusAnimation:setLooping(true)
  statusAnimation:start()

  self.statusAnimation = statusAnimation
end

function VehicleCameraSystemHUDExtension:update(dt)
  self.isCameraRenderable = self.vehicle:getIsCameraActive()

  if self.isSplashScreenAnimation and self.isSplashScreen then
    if self.vehicleCameraSystem.lastCameraState == VehicleCameraSystem.CAMERA_STATE.OFF then
      self.brandAnimation:reset()
      self.brandAnimation:start()
    end

    self.isSplashScreenAnimation = false
  end

  if self.vehicleCameraSystem.currentCamera ~= nil then
    if self.vehicleCameraSystem.currentCamera ~= self.currentRenderCamera then
      if self.cameraRender.scene then
        self.cameraRender:link(self.vehicleCameraSystem.currentCamera)

        self.currentRenderCamera = self.vehicleCameraSystem.currentCamera
      end
    end
  end

  if not self.brandAnimation:getFinished() then
    self.brandAnimation:update(dt)
  elseif self.isSplashScreen then
    self.isSplashScreen = false
    self.vehicleCameraSystem.isEntered = false

    self:setBrandAlphaChannel(1)
  end

  if not self.isSplashScreen and self.isCameraRenderable then
    self.statusAnimation:update(dt)
    self.cameraRender:update(dt)
  end
end

function VehicleCameraSystemHUDExtension:draw(leftPosX, rightPosX, posY)
  if not self:canDraw() then
    return
  end

  if not self.isSplashScreen and self.isCameraRenderable then
    if self.vehicleCameraSystem.currentCamera ~= nil then
      local cameraIdText = string.format(self.texts.id, self.vehicleCameraSystem.currentCamera.id, #self.vehicleCameraSystem.cameras)

      self.cameraRender:draw(((leftPosX + rightPosX) / 2) - self.cameraRenderWidth / 2, posY + ((self.displayHeight * 0.5) - self.cameraRenderHeight / 2))

      setTextColor(unpack(self.uiTextColor))
      setTextBold(true)
      setTextAlignment(RenderText.ALIGN_CENTER)
      renderText((leftPosX + rightPosX) / 2, posY + (self.displayHeight - (self.cameraNameTextHeight + self.cameraNameTextOffset)), self.cameraNameTextHeight, Utils.limitTextToWidth(self.vehicleCameraSystem.currentCamera.name, self.cameraNameTextHeight, self.cameraNameMaxTextWidth, false, "..."))
      setTextBold(false)

      setTextAlignment(RenderText.ALIGN_RIGHT)
      renderText(rightPosX, posY + (self.displayHeight - self.cameraIdTextHeight - self.cameraIdTextOffset) + self.inputHelpDisplayOffsetX, self.cameraIdTextHeight, cameraIdText)

      self.statusOverlay:setPosition(leftPosX + (self.inputHelpDisplayOffsetX / 2) + self.statusOverlayOffsetX, posY + ((self.displayHeight - self.statusOverlay.height) + self.inputHelpDisplayOffsetX))
      self.statusOverlay:render()
    else
      setTextColor(unpack(self.uiTextColor))
      setTextBold(true)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
      renderText((leftPosX + rightPosX) / 2, posY + (self.displayHeight * 0.5), self.errorTextHeight, self.texts.error)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
      setTextBold(false)
    end
  end

  if self.isSplashScreen or not self.isCameraRenderable then
    self.brandOverlay:setPosition(((leftPosX + rightPosX) / 2) - self.brandOverlay.width / 2, posY + ((self.displayHeight * 0.5) - self.brandOverlay.height / 2))
    self.brandOverlay:render()
  end

  return posY
end

function VehicleCameraSystemHUDExtension:setBrandAlphaChannel(alpha)
  self.brandOverlay:setColor(nil, nil, nil, alpha)
end

function VehicleCameraSystemHUDExtension:setStatusColorChannels(r, g, b, a)
  self.statusOverlay:setColor(r, g, b, a)
end

function VehicleCameraSystemHUDExtension:canDraw()
  if self.vehicleCameraSystem.hasCameras and self.vehicle:getIsCameraSystemActive() then
    return true
  end

  return false
end

function VehicleCameraSystemHUDExtension:getPriority()
  return 1
end

function VehicleCameraSystemHUDExtension:getDisplayHeight()
  return self:canDraw() and self.displayHeight or 0
end

function VehicleCameraSystemHUDExtension:getHelpEntryCountReduction()
  return self:canDraw() and 1 or 0
end

function VehicleCameraSystemHUDExtension:delete()
  VehicleCameraSystemHUDExtension:superClass().delete(self)

  if self.cameraRender ~= nil then
    self.cameraRender:delete()
  end
end

VehicleCameraSystemHUDExtension.UV = {
  STATUS = {
    0,
    0,
    66,
    48
  }
}

VehicleCameraSystemHUDExtension.COLOR = {
  STATUS = {
    OFF = {
      1,
      1,
      1,
      1
    },
    ON = {
      0.0003,
      0.5647,
      0.9822,
      1
    }
  },
  BRAND = {
    VISIBLE = {
      1
    },
    INVISIBLE = {
      0
    }
  }
}

VehicleCameraSystemHUDExtension.ANIMATION = {
  TIME = {
    FADE = 800,
    BLINK = 800
  },
  SHOW_TIME = {
    FADE = 1500,
    BLINK = 150
  }
}