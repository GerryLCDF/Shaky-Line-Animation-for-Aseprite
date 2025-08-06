--creditos Gerry and Garibaldi
local spr = app.activeSprite
if not spr then
  app.alert("アクティブなスプライトがありません。")
  return
end

local layerNames = { "全レイヤー" }
local layers = { "ALL" }

for _, layer in ipairs(spr.layers) do
  if not layer.isGroup and layer.isVisible then
    table.insert(layerNames, layer.name)
    table.insert(layers, layer)
  end
end

if #layers == 1 then
  app.alert("効果を適用する可視イメージレイヤーがありません。")
  return
end

local function showHelp()
  app.alert{
    title = "パラメータヘルプ",
    text = {
      "レイヤー:",
      "  - 効果を適用するレイヤーを選択します。",
      "  - 「全レイヤー」を選ぶと、すべての可視レイヤーに適用されます。",
      "",
      "追加フレーム:",
      "  - シェイク効果を持つ新しいフレームの数。",
      "  - 元のフレームに追加されます。",
      "",
      "シェイク量:",
      "  - ピクセルがどれだけ移動するか。",
      "  - 推奨: 微振動なら低値（0-2）。",
      "",
      "密度:",
      "  - 内部を埋めるためのピクセルコピー数。",
      "  - 高い値 = よりソリッドで詰まった線。",
      "",
      "✔️ パラメータを調整して、お好みのシェイク効果を作成してください。"
    }
  }
end

local dlg = Dialog { title = "シェイキーライン設定" }
dlg:combobox{ id="layer", label="レイヤー:", options=layerNames, option=layerNames[1] }
dlg:number{ id="frames", label="追加フレーム:", text="4" }
dlg:number{ id="shake", label="シェイク量 (0-2):", text="1" }
dlg:number{ id="density", label="密度 (コピー):", text="8" }
dlg:button{ id = "help", text = "?", onclick = showHelp }
dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="キャンセル" }
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

