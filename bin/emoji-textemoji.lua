-- emoji-textemoji.lua
-- UTF-8 safe Pandoc Lua filter for LaTeX:
-- * Normalizes some punctuation (without corrupting multibyte Unicode)
-- * Rewrites arrows, ⸻, math-ish symbols, and selected emojis anywhere inside Str
-- * Normalizes Code and CodeBlock to ASCII equivalents

local function replace_all_literal(s, map)
  for k, v in pairs(map) do
    s = s:gsub(k, v)
  end
  return s
end

local TEXT_NORMALIZE = {
  ["\u{2010}"] = "-",  -- hyphen
  ["\u{2011}"] = "-",  -- non-breaking hyphen
  ["\u{2012}"] = "-",  -- figure dash
  ["\u{2013}"] = "-",  -- en dash
  ["\u{2014}"] = "-",  -- em dash
  ["\u{2212}"] = "-",  -- minus sign

  ["\u{2018}"] = "'",  -- left single quote
  ["\u{2019}"] = "'",  -- right single quote
  ["\u{201B}"] = "'",  -- single high reversed 9
  ["\u{201C}"] = '"',  -- left double quote
  ["\u{201D}"] = '"',  -- right double quote
  ["\u{201F}"] = '"',  -- double high reversed 9
}

local function strip_variation_selectors(s)
  s = s:gsub("\u{FE0F}", "")
  s = s:gsub("\u{FE0E}", "")
  s = s:gsub("️", "")
  return s
end

local function normalize_text(s)
  s = replace_all_literal(s, TEXT_NORMALIZE)
  s = strip_variation_selectors(s)
  return s
end

local function normalize_code(s)
  s = normalize_text(s)
  s = s:gsub("→", "->")
  s = s:gsub("➝", "->")
  s = s:gsub("⸻", "---")
  return s
end

function Code(el)
  if FORMAT == "latex" then
    el.text = normalize_code(el.text)
  end
  return el
end

function CodeBlock(el)
  if FORMAT == "latex" then
    el.text = normalize_code(el.text)
  end
  return el
end

local INLINE_MAP = {
  ["→"] = "\\symbolarrow{}",
  ["➝"] = "\\symbolarrow{}",

  ["⸻"] = "\\threeemdash{}",

  ["≤"] = "\\ensuremath{\\le{}}",
  ["≈"] = "\\ensuremath{\\approx{}}",

  ["✅"] = "\\emojicheckmark{}",
  ["❌"] = "\\emojicrossmark{}",
  ["🎯"] = "\\emojitarget{}",
  ["🎬"] = "\\emojifilm{}",
  ["📹"] = "\\emojivideo{}",
  ["🎥"] = "\\emojivideo{}",
  ["🧠"] = "\\emojibrain{}",
  ["🔧"] = "\\emojitool{}",
  ["🛠"] = "\\emojitool{}",
  ["📣"] = "\\emojimegaphone{}",
  ["📈"] = "\\emojichart{}",
  ["🔍"] = "\\emojisearch{}",
  ["🔜"] = "\\emojisoon{}",
  ["💄"] = "\\emojimakeup{}",
  ["🤝"] = "\\emojihandshake{}",
  ["💭"] = "\\emojithought{}",
  ["🎲"] = "\\emojidice{}",
  ["🌱"] = "\\emojiSeedling{}",
  ["🌐"] = "\\emojiGlobe{}",
}

local function needs_rewrite(s)
  for ch, _ in pairs(INLINE_MAP) do
    if s:find(ch, 1, true) then return true end
  end
  return false
end

function Str(el)
  if FORMAT ~= "latex" then return nil end

  local s = normalize_text(el.text)

  if not needs_rewrite(s) then
    el.text = s
    return el
  end

  local out = pandoc.List()
  local buf = ""

  for _, cp in utf8.codes(s) do
    local ch = utf8.char(cp)
    local latex = INLINE_MAP[ch]
    if latex then
      if buf ~= "" then
        out:insert(pandoc.Str(buf))
        buf = ""
      end
      out:insert(pandoc.RawInline("latex", latex))
    else
      buf = buf .. ch
    end
  end

  if buf ~= "" then
    out:insert(pandoc.Str(buf))
  end

  return out
end
