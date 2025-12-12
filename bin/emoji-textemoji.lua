-- emoji-textemoji.lua
-- Pandoc Lua filter: map certain Unicode and emoji to LaTeX-safe forms,
-- and normalize special hyphens in verbatim/code.

-- Normalize hyphens/dashes/minus and smart quotes everywhere
local function normalize_all(s)
  -- Hyphen / dash / minus family:
  --  U+2010: hyphen
  --  U+2011: non-breaking hyphen
  --  U+2013: en dash
  --  U+2014: em dash
  --  U+2212: minus sign
  s = s:gsub("[\u{2010}\u{2011}\u{2013}\u{2014}\u{2212}]", "-")

  -- Smart quotes:
  --  U+2018 / U+2019: single quotes
  --  U+201C / U+201D: double quotes
  s = s:gsub("\u{2018}", "'"):gsub("\u{2019}", "'")
  s = s:gsub("\u{201C}", '"'):gsub("\u{201D}", '"')

  -- Strip variation selectors, if any
  s = s:gsub("[\u{FE0F}\u{FE0E}]", ""):gsub("", "")

  return s
end


function Code(el)
  if FORMAT == "latex" then
    el.text = normalize_all(el.text)
  end
  return el
end

function CodeBlock(el)
  if FORMAT == "latex" then
    el.text = normalize_all(el.text)
  end
  return el
end


-- Inline string mapping for LaTeX output
function Str(el)
  if FORMAT ~= "latex" then return nil end
  local s = el.text

  -- Normalize non-breaking hyphens in normal text
  s = normalize_all(s)

  -- Strip variation selectors
  s = s:gsub("[\u{FE0F}\u{FE0E}]", ""):gsub("", "")

  -- Emoji / symbol logic stays the same
  if s == "➝" or s == "→" then
    return pandoc.RawInline("latex", "\\symbolarrow{}")
  elseif s == "≤" then
    return pandoc.RawInline("latex", "\\ensuremath{\\le{}}")
  elseif s == "≈" then
    return pandoc.RawInline("latex", "\\ensuremath{\\approx{}}")
  elseif s == "✅" then
    return pandoc.RawInline("latex", "\\emojicheckmark{}")
  elseif s == "🎯" then
    return pandoc.RawInline("latex", "\\emojitarget{}")
  elseif s == "🎬" then
    return pandoc.RawInline("latex", "\\emojifilm{}")
  elseif s == "📹" or s == "🎥" then
    return pandoc.RawInline("latex", "\\emojivideo{}")
  elseif s == "🧠" then
    return pandoc.RawInline("latex", "\\emojibrain{}")
  elseif s == "🔧" or s == "🛠" then
    return pandoc.RawInline("latex", "\\emojitool{}")
  elseif s == "📣" then
    return pandoc.RawInline("latex", "\\emojimegaphone{}")
  elseif s == "📈" then
    return pandoc.RawInline("latex", "\\emojichart{}")
  elseif s == "🔍" then
    return pandoc.RawInline("latex", "\\emojisearch{}")
  elseif s == "🔜" then
    return pandoc.RawInline("latex", "\\emojisoon{}")
  elseif s == "💄" then
    return pandoc.RawInline("latex", "\\emojimakeup{}")
  elseif s == "🤝" then
    return pandoc.RawInline("latex", "\\emojihandshake{}")
  elseif s == "💭" then
    return pandoc.RawInline("latex", "\\emojithought{}")
  elseif s == "🎲" then
    return pandoc.RawInline("latex", "\\emojidice{}")
  elseif s == "🌐" then
    return pandoc.RawInline("latex", "\\emojiGlobe{}")
  end

  -- Return normalized string for normal text
  el.text = s
  return el
end

