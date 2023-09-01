-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 09|08|2023
-- @filename: CameraSystemHUDExtension.lua

-- Changelog (1.0.0.1):
-- changed compatibility with vehicle specialization
-- improved status animation
-- cleaned code

CameraSystemHUDExtension = {
  MOD_DIRECTORY = g_currentModDirectory
}

CameraSystemHUDExtension.HUD_ELEMENTS = CameraSystemHUDExtension.MOD_DIRECTORY .. "data/menu/hud/hud_elements.png"

local VehicleCameraSystemHUDExtension_mt = Class(CameraSystemHUDExtension, VehicleHUDExtension)

function CameraSystemHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
  local self = VehicleHUDExtension.new(VehicleCameraSystemHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)

  _, self.displayHeight = getNormalizedScreenValues(0, ((InputHelpDisplay.WIDTH / 2) + 4.5) * uiScale)
  self.cameraRenderWidth, self.cameraRenderHeight = getNormalizedScreenValues((InputHelpDisplay.WIDTH - 2) * uiScale, ((InputHelpDisplay.WIDTH / 2) + 2) * uiScale)
  self.cameraNameTextOffset, self.cameraNameTextHeight = getNormalizedScreenValues(13 * uiScale, 20 * uiScale)
  self.cameraNameMaxTextWidth, _ = getNormalizedScreenValues(300 * uiScale, 0)
  self.cameraIdTextOffset, self.cameraIdTextHeight = getNormalizedScreenValues(2 * uiScale, 16 * uiScale)
  self.statusOverlayOffsetX, _ = getNormalizedScreenValues(3 * uiScale, 0)
  _, self.infoTextHeight = getNormalizedScreenValues(0, 18 * uiScale)
  self.inputHelpDisplayOffsetX, _ = getNormalizedScreenValues(InputHelpDisplay.POSITION.AXIS_ICON[1] * uiScale, 0)

  local width, height = getNormalizedScreenValues(30 * uiScale, 22 * uiScale)

  self.statusOverlay = Overlay.new(CameraSystemHUDExtension.HUD_ELEMENTS, 0, 0, width, height)
  self.statusOverlay:setUVs(GuiUtils.getUVs(CameraSystemHUDExtension.UV.STATUS))
  self.statusOverlay:setColor(unpack(CameraSystemHUDExtension.COLOR.STATUS.OFF))

  self:addComponentForCleanup(self.statusOverlay)

  width, height = getNormalizedScreenValues(256 * uiScale, 128 * uiScale)

  local brand = vehicle.brand.imageShopOverview or g_brandManager:getBrandByIndex(Brand.LIZARD).imageShopOverview

  self.brandOverlay = Overlay.new(brand, 0, 0, width, height)
  self.brandOverlay:setColor(nil, nil, nil, 1)

  self:addComponentForCleanup(self.brandOverlay)

  self.texts = {
    id = g_i18n:getText("ui_cameraSystem_id")
  }

  self.brandAnimation = TweenSequence.NO_SEQUENCE
  self.statusAnimation = TweenSequence.NO_SEQUENCE

  self.isSplashScreen = vehicle.spec_cameraSystemEnterable.isDirty
  self.isSplashScreenAnimation = true

  self:createAnimations()

  return self
end

function CameraSystemHUDExtension:createAnimations()
  local brandAnimation = TweenSequence.new(self)

  brandAnimation:addInterval(CameraSystemHUDExtension.ANIMATION.SHOW_TIME.FADE)
  brandAnimation:addTween(MultiValueTween.new(self.setBrandAlphaChannel, CameraSystemHUDExtension.COLOR.BRAND.VISIBLE, CameraSystemHUDExtension.COLOR.BRAND.INVISIBLE, CameraSystemHUDExtension.ANIMATION.TIME.FADE))

  self.brandAnimation = brandAnimation

  local statusAnimation = TweenSequence.new(self)

  statusAnimation:addTween(MultiValueTween.new(self.setStatusColorChannels, CameraSystemHUDExtension.COLOR.STATUS.OFF, CameraSystemHUDExtension.COLOR.STATUS.ON, CameraSystemHUDExtension.ANIMATION.TIME.BLINK))
  statusAnimation:addInterval(CameraSystemHUDExtension.ANIMATION.SHOW_TIME.BLINK)
  statusAnimation:addTween(MultiValueTween.new(self.setStatusColorChannels, CameraSystemHUDExtension.COLOR.STATUS.ON, CameraSystemHUDExtension.COLOR.STATUS.OFF, CameraSystemHUDExtension.ANIMATION.TIME.BLINK))
  statusAnimation:setLooping(true)
  statusAnimation:start()

  self.statusAnimation = statusAnimation
end

function CameraSystemHUDExtension:update(dt)
  if self.isSplashScreenAnimation and self.isSplashScreen then
    self.brandAnimation:reset()
    self.brandAnimation:start()

    self.isSplashScreenAnimation = false
  end

  if not self.brandAnimation:getFinished() then
    self.brandAnimation:update(dt)
  elseif self.isSplashScreen then
    self.isSplashScreen = false

    self.vehicle.spec_cameraSystemEnterable.isDirty = false

    self:setBrandAlphaChannel(1)
  end

  if not self.isSplashScreen then
    local activeCamera = self.vehicle:getCameraSystemActiveCamera()

    if activeCamera ~= nil then
      local isActive = self.vehicle:getCameraSystemIsCameraActive(activeCamera)

      if isActive then
        if self.statusAnimation:getFinished() then
          self.statusAnimation:reset()
          self.statusAnimation:start()
        end

        self.statusAnimation:update(dt)

        activeCamera:update(dt)
      elseif not self.statusAnimation:getFinished() then
        self.statusAnimation:stop()

        self.statusOverlay:setColor(unpack(CameraSystemHUDExtension.COLOR.STATUS.OFF))
      end
    end
  end
end

function CameraSystemHUDExtension:draw(leftPosX, rightPosX, posY)
  if not self:canDraw() then
    return
  end

  if not self.isSplashScreen then
    local activeCamera = self.vehicle:getCameraSystemActiveCamera()

    if activeCamera ~= nil then
      local isActive, infoText = self.vehicle:getCameraSystemIsCameraActive(activeCamera)
      local cameraIdText = string.format(self.texts.id, self.vehicle:getCameraSystemActiveCameraIndex(), self.vehicle:getNumOfCameraSystemCameras())

      setTextColor(unpack(self.uiTextColor))
      setTextBold(true)
      setTextAlignment(RenderText.ALIGN_CENTER)
      renderText((leftPosX + rightPosX) / 2, posY + (self.displayHeight - (self.cameraNameTextHeight + self.cameraNameTextOffset)), self.cameraNameTextHeight, Utils.limitTextToWidth(activeCamera.name, self.cameraNameTextHeight, self.cameraNameMaxTextWidth, false, "..."))
      setTextBold(false)

      setTextAlignment(RenderText.ALIGN_RIGHT)
      renderText(rightPosX, posY + (self.displayHeight - self.cameraIdTextHeight - self.cameraIdTextOffset) + self.inputHelpDisplayOffsetX, self.cameraIdTextHeight, cameraIdText)

      if isActive then
        activeCamera:draw(((leftPosX + rightPosX) / 2) - (self.cameraRenderWidth / 2), posY + ((self.displayHeight * 0.5) - (self.cameraRenderHeight / 2)), self.cameraRenderWidth, self.cameraRenderHeight)
      else
        setTextColor(unpack(self.uiTextColor))
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        renderText((leftPosX + rightPosX) / 2, posY + (self.displayHeight * 0.5), self.infoTextHeight, infoText)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        setTextBold(false)
      end

      self.statusOverlay:setPosition(leftPosX + (self.inputHelpDisplayOffsetX / 2) + self.statusOverlayOffsetX, posY + ((self.displayHeight - self.statusOverlay.height) + self.inputHelpDisplayOffsetX))
      self.statusOverlay:render()
    end
  else
    self.brandOverlay:setPosition(((leftPosX + rightPosX) / 2) - (self.brandOverlay.width / 2), posY + ((self.displayHeight * 0.5) - (self.brandOverlay.height / 2)))
    self.brandOverlay:render()
  end

  return posY
end

function CameraSystemHUDExtension:setBrandAlphaChannel(alpha)
  self.brandOverlay:setColor(nil, nil, nil, alpha)
end

function CameraSystemHUDExtension:setStatusColorChannels(r, g, b, a)
  self.statusOverlay:setColor(r, g, b, a)
end

function CameraSystemHUDExtension:canDraw()
  if self.vehicle:getHasCameraSystem() and self.vehicle:getIsCameraSystemActive() then
    return true
  end

  return false
end

function CameraSystemHUDExtension:getPriority()
  return 1
end

function CameraSystemHUDExtension:getDisplayHeight()
  return self:canDraw() and self.displayHeight or 0
end

function CameraSystemHUDExtension:getHelpEntryCountReduction()
  return self:canDraw() and 1 or 0
end

CameraSystemHUDExtension.UV = {
  STATUS = {
    0,
    0,
    66,
    48
  }
}

CameraSystemHUDExtension.COLOR = {
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

CameraSystemHUDExtension.ANIMATION = {
  TIME = {
    FADE = 800,
    BLINK = 800
  },
  SHOW_TIME = {
    FADE = 1500,
    BLINK = 150
  }
}