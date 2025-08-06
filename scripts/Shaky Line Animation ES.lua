--creditos Gerry and Garibaldi
local spr = app.activeSprite
if not spr then
  app.alert("No hay sprite activo.")
  return
end

-- Recoger layers disponibles
local layerNames = { "ALL Layers" }
local layers = { "ALL" }

for _, layer in ipairs(spr.layers) do
  if not layer.isGroup and layer.isVisible then
    table.insert(layerNames, layer.name)
    table.insert(layers, layer)
  end
end

if #layers == 1 then
  app.alert("No hay layers de imagen visibles para aplicar el efecto.")
  return
end

-- Función de ayuda
local function showHelp()
  app.alert{
    title = "Ayuda de parámetros",
    text = {
      "Layer:",
      "  - Selecciona el layer al que aplicar el efecto.",
      "  - Si eliges ALL Layers, se aplicará a todos los layers visibles.",
      "",
      "Frames adicionales:",
      "  - Cuántos frames nuevos se crearán con efecto shaky.",
      "  - Se suman al frame original.",
      "",
      "Shake amount:",
      "  - Qué tanto se moverán los píxeles.",
      "  - Recomendado: valores bajos (0-2) para vibración sutil.",
      "",
      "Densidad:",
      "  - Cuántas copias se dibujan por píxel para rellenar el interior.",
      "  - Valores altos = líneas más sólidas y rellenas.",
      "",
      "✔️ Ajusta estos parámetros para lograr el efecto tembloroso que más te guste."
    }
  }
end

-- Diálogo
local dlg = Dialog { title = "Shaky Line Settings" }
dlg:combobox{ id="layer", label="Layer:", options=layerNames, option=layerNames[1] }
dlg:number{ id="frames", label="Frames adicionales:", text="4" }
dlg:number{ id="shake", label="Shake amount (0-2):", text="1" }
dlg:number{ id="density", label="Densidad (copias):", text="8" }
dlg:button{
  id = "help",
  text = "?",
  onclick = showHelp
}
dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="Cancelar" }
dlg:show()

local data = dlg.data
if not data.ok then
  return
end

local numExtraFrames = data.frames
local shakeAmount = data.shake
local density = data.density

-- Encontrar layer seleccionado
local selectedLayer = nil
for i, name in ipairs(layerNames) do
  if name == data.layer then
    selectedLayer = layers[i]
    break
  end
end

-- Crear lista de layers a procesar
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

-- Función para generar imagen shaky
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

  -- Crear frames adicionales primero
  for i = 1, numExtraFrames do
    spr:newFrame()
  end

  for _, layer in ipairs(targetLayers) do
    local cel = layer:cel(originalFrame)
    if not cel then
      goto continue
    end

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

