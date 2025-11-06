-- emoji-textemoji.lua
-- Pandoc Lua filter: map certain Unicode and emoji to LaTeX-safe forms,
-- and normalize special hyphens in verbatim/code.

-- Normalize variation selectors, NB hyphen etc. in *verbatim* contexts
local function normalize_verbatim(s)
  -- Replace non-breaking hyphen (U+2011) and hyphen (U+2010) with ASCII hyphen
  s = s:gsub("\u{2011}", "-"):gsub("\u{2010}", "-")
  -- Strip variation selectors if they sneak in
  s = s:gsub("[\u{FE0F}\u{FE0E}]", ""):gsub("️", "")
  return s
end

function Code(el)
  if FORMAT == "latex" then
    el.text = normalize_verbatim(el.text)
  end
  return el
end

function CodeBlock(el)
  if FORMAT == "latex" then
    el.text = normalize_verbatim(el.text)
  end
  return el
end

-- Inline string mapping for LaTeX output
function Str(el)
  if FORMAT ~= "latex" then return nil end
  local s = el.text

  -- Strip variation selectors
  s = s:gsub("[\u{FE0F}\u{FE0E}]", ""):gsub("️", "")

  -- Map common arrows and math-ish symbols
  if s == "➝" or s == "→" then
    return pandoc.RawInline("latex", "\\symbolarrow{}")
  elseif s == "≤" then
    return pandoc.RawInline("latex", "\\ensuremath{\\le{}}")
  elseif s == "≈" then
    return pandoc.RawInline("latex", "\\ensuremath{\\approx{}}")

  -- Emojis (extend as needed)
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
  end

  -- Let Pandoc handle everything else
  return nil
end
