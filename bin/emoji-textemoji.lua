-- emoji-textemoji.lua
-- UTF-8 safe Pandoc Lua filter for LaTeX output
-- 1) Normalizes a few punctuation characters safely (no byte based [] classes)
-- 2) Rewrites arrows, math-ish symbols, and selected emojis to LaTeX macros
-- 3) Normalizes code and code blocks (arrows become -> in code)

local function replace_all_literal(s, map)
  for k, v in pairs(map) do
    -- k contains no Lua pattern magic, so this is literal-safe
    s = s:gsub(k, v)
  end
  return s
end

local TEXT_NORMALIZE = {
  ["\u{2010}"] = "-",  -- hyphen
  ["\u{2011}"] = "-",  -- non breaking hyphen
  ["\u{2013}"] = "-",  -- en dash
  ["\u{2014}"] = "-",  -- em dash
  ["\u{2212}"] = "-",  -- minus sign

  ["\u{2018}"] = "'",  -- left single quote
  ["\u{2019}"] = "'",  -- right single quote
  ["\u{201C}"] = '"',  -- left double quote
  ["\u{201D}"] = '"',  -- right double quote
}

local function strip_variation_selectors(s)
  -- VS16, VS15
  s = s:gsub("\u{FE0F}", "")
  s = s:gsub("\u{FE0E}", "")
  -- some editors paste the visible VS glyph too
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
  -- in code, keep it ASCII
  s = s:gsub("→", "->")
  s = s:gsub("➝", "->")
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

-- Map single characters to LaTeX inlines
local INLINE_MAP = {
  ["→"] = pandoc.RawInline("latex", "\\symbolarrow{}"),
  ["➝"] = pandoc.RawInline("latex", "\\symbolarrow{}"),

  ["≤"] = pandoc.RawInline("latex", "\\ensuremath{\\le{}}"),
  ["≈"] = pandoc.RawInline("latex", "\\ensuremath{\\approx{}}"),

  ["✅"] = pandoc.RawInline("latex", "\\emojicheckmark{}"),
  ["❌"] = pandoc.RawInline("latex", "\\emojicrossmark{}"),
  ["🎯"] = pandoc.RawInline("latex", "\\emojitarget{}"),
  ["🎬"] = pandoc.RawInline("latex", "\\emojifilm{}"),
  ["📹"] = pandoc.RawInline("latex", "\\emojivideo{}"),
  ["🎥"] = pandoc.RawInline("latex", "\\emojivideo{}"),
  ["🧠"] = pandoc.RawInline("latex", "\\emojibrain{}"),
  ["🔧"] = pandoc.RawInline("latex", "\\emojitool{}"),
  ["🛠"] = pandoc.RawInline("latex", "\\emojitool{}"),
  ["📣"] = pandoc.RawInline("latex", "\\emojimegaphone{}"),
  ["📈"] = pandoc.RawInline("latex", "\\emojichart{}"),
  ["🔍"] = pandoc.RawInline("latex", "\\emojisearch{}"),
  ["🔜"] = pandoc.RawInline("latex", "\\emojisoon{}"),
  ["💄"] = pandoc.RawInline("latex", "\\emojimakeup{}"),
  ["🤝"] = pandoc.RawInline("latex", "\\emojihandshake{}"),
  ["💭"] = pandoc.RawInline("latex", "\\emojithought{}"),
  ["🎲"] = pandoc.RawInline("latex", "\\emojidice{}"),
  ["🌱"] = pandoc.RawInline("latex", "\\emojiSeedling{}"),
  ["🌐"] = pandoc.RawInline("latex", "\\emojiGlobe{}"),
}

local function rewrite_str_to_inlines(s)
  local out = pandoc.List()
  local buf = ""

  for _, cp in utf8.codes(s) do
    local ch = utf8.char(cp)
    local repl = INLINE_MAP[ch]
    if repl then
      if buf ~= "" then
        out:insert(pandoc.Str(buf))
        buf = ""
      end
      out:insert(repl)
    else
      buf = buf .. ch
    end
  end

  if buf ~= "" then
    out:insert(pandoc.Str(buf))
  end

  return out
end

function Str(el)
  if FORMAT ~= "latex" then return nil end

  local s = normalize_text(el.text)

  -- Fast path, if no mapped characters exist, just return normalized text
  -- (still safe if we skip this, but keeps output closer to Pandoc defaults)
  if not (
    s:find("→", 1, true) or s:find("➝", 1, true) or
    s:find("≤", 1, true) or s:find("≈", 1, true) or
    s:find("✅", 1, true) or s:find("❌", 1, true) or
    s:find("🎯", 1, true) or s:find("🎬", 1, true) or
    s:find("📹", 1, true) or s:find("🎥", 1, true) or
    s:find("🧠", 1, true) or s:find("🔧", 1, true) or
    s:find("🛠", 1, true) or s:find("📣", 1, true) or
    s:find("📈", 1, true) or s:find("🔍", 1, true) or
    s:find("🔜", 1, true) or s:find("💄", 1, true) or
    s:find("🤝", 1, true) or s:find("💭", 1, true) or
    s:find("🎲", 1, true) or s:find("🌱", 1, true) or
    s:find("🌐", 1, true)
  ) then
    el.text = s
    return el
  end

  return rewrite_str_to_inlines(s)
end

