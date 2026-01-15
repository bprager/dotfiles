function Span(el)
  -- 1. Lookup table: class name -> LaTeX color name
  local colors = {
    -- Standard Indicators
    red = "red",
    green = "ForestGreen",
    blue = "blue",
    yellow = "orange", -- Remapped for visibility on white paper

    -- Business Palette
    orange = "orange",
    purple = "violet",
    cyan = "cyan",
    magenta = "magenta",
    navy = "NavyBlue",
    maroon = "Maroon",
    teal = "TealBlue",
    olive = "OliveGreen",
    brown = "Brown",
    lime = "LimeGreen",

    -- Grayscale
    gray = "gray",
    darkgray = "darkgray",
    black = "black"
  }

  -- 2. Detect Attributes
  local text_color = nil
  local is_highlight = false

  -- Loop through all classes applied to the span
  for _, class in ipairs(el.classes) do
    if colors[class] then
      text_color = colors[class]
    elseif class == "highlight" then
      is_highlight = true
    end
  end

  -- 3. Construct LaTeX Output
  if text_color or is_highlight then
    local content = pandoc.utils.stringify(el)

    -- Apply text color if found
    if text_color then
      content = '\\textcolor{' .. text_color .. '}{' .. content .. '}'
    end

    -- Apply background highlight if found
    if is_highlight then
      content = '\\colorbox{yellow}{' .. content .. '}'
    end

    return pandoc.RawInline('latex', content)
  end

  -- Return original if no matches
  return el
end
