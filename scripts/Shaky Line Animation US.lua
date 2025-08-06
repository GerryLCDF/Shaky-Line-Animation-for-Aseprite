--creditos Gerry and Garibaldi

local spr = app.activeSprite
if not spr then
  app.alert("No active sprite.")
  return
end

local layerNames = { "ALL Layers" }
local layers = { "ALL" }

for _, layer in ipairs(spr.layers) do
  if not layer.isGroup and layer.isVisible then
    table.insert(layerNames, layer.name)
    table.insert(layers, layer)
  end
end

if #layers == 1 then
  app.alert("No visible image layers to apply the effect.")
  return
end

local function showHelp()
  app.alert{
    title = "Parameter Help",
    text = {
      "Layer:",
      "  - Select the layer to apply the effect to.",
      "  - If you choose ALL Layers, it will apply to all visible layers.",
      "",
      "Extra frames:",
      "  - How many new frames will be created with the shaky effect.",
      "  - These are added to the original frame.",
      "",
      "Shake amount:",
      "  - How much the pixels will move.",
      "  - Recommended: low values (0-2) for subtle vibration.",
      "",
      "Density:",
      "  - How many copies per pixel to fill the interior.",
      "  - Higher values = more solid and filled lines.",
      "",
      "✔️ Adjust these parameters to achieve your preferred shaky effect."
    }
  }
end

local dlg = Dialog { title = "Shaky Line Settings" }
dlg:combobox{ id="layer", label="Layer:", options=layerNames, option=layerNames[1] }
dlg:number{ id="frames", label="Extra frames:", text="4" }
dlg:number{ id="shake", label="Shake amount (0-2):", text="1" }
dlg:number{ id="density", label="Density (copies):", text="8" }
dlg:button{ id = "help", text = "?", onclick = showHelp }
dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

local data = dlg.data
if not data.ok then return end

local numExtraFrames = data.frames
local shakeAmount = data.shake
local density = data.density

local selectedLayer = nil
for i, name in ipairs(layerNames) do
  if name == data.layer then
    selectedLayer = layers[i]
    break
  end
end

local targetLayers = {}
if selectedLayer == "ALL" then
  for _, layer in ipairs(spr.layers) do
    if not layer.isGroup and layer.isVisible then
      table.insert(targetLayers, layer)
    end
  end
else
  table.insert(targetLayers, selectedLayer)
end

local function generateShakyImage(image, shakeAmount, density)
  local shaky = Image(image.width, image.height, image.colorMode)
  shaky:clear()

  local bounds = image.bounds
  for y = bounds.y, bounds.y + bounds.height - 1 do
    for x = bounds.x, bounds.x + bounds.width - 1 do
      local c = image:getPixel(x, y)
      if c ~= 0 then
        for d = 1, density do
          local offsetX = x + math.random(-shakeAmount, shakeAmount)
          local offsetY = y + math.random(-shakeAmount, shakeAmount)
          if offsetX >= 0 and offsetX < shaky.width and offsetY >= 0 and offsetY < shaky.height then
            shaky:drawPixel(offsetX, offsetY, c)
          end
        end
      end
    end
  end
  return shaky
end

app.transaction(function()
  local originalFrame = app.activeFrame
  local totalFrames = numExtraFrames + 1

  for i = 1, numExtraFrames do
    spr:newFrame()
  end

  for _, layer in ipairs(targetLayers) do
    local cel = layer:cel(originalFrame)
    if not cel then goto continue end

    local originalImage = cel.image
    local pos = cel.position
    local baseImg = originalImage:clone()

    for f = 1, totalFrames do
      local frame = spr.frames[f]
      local shakyImage = generateShakyImage(baseImg, shakeAmount, density)

      local targetCel = layer:cel(frame)
      if targetCel then
        targetCel.image = shakyImage
        targetCel.position = pos
      else
        app.activeSprite:newCel(layer, frame, shakyImage, pos)
      end
    end

    ::continue::
  end

  app.activeFrame = originalFrame
end)

app.refresh()

