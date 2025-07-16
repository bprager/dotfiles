-- emoji-textemoji.lua
-- Process emojis and special characters for LaTeX output using AST processing

-- Process individual string elements
function Str(el)
  if FORMAT == "latex" then
    local s = el.text

    -- Remove variation selectors
    s = s:gsub("[\u{FE0F}\u{FE0E}]", "")
    s = s:gsub("️", "")

    -- Handle specific characters with fallback support
    if s == "➝" then
      return pandoc.RawInline("latex", "\\symbolarrow{}")
    elseif s == "✅" then
      return pandoc.RawInline("latex", "\\emojicheckmark{}")
    elseif s == "🎯" then
      return pandoc.RawInline("latex", "\\emojitarget{}")
    elseif s == "🎬" then
      return pandoc.RawInline("latex", "\\emojifilm{}")
    elseif s == "📹" then
      return pandoc.RawInline("latex", "\\emojivideo{}")
    elseif s == "🧠" then
      return pandoc.RawInline("latex", "\\emojibrain{}")
    elseif s == "🔧" then
      return pandoc.RawInline("latex", "\\emojitool{}")
    elseif s == "📣" then
      return pandoc.RawInline("latex", "\\emojimegaphone{}")
    elseif s == "📈" then
      return pandoc.RawInline("latex", "\\emojichart{}")
    elseif s == "🔍" then
      return pandoc.RawInline("latex", "\\emojisearch{}")
    elseif s == "🔜" then
      return pandoc.RawInline("latex", "\\emojisoon{}")
    elseif s == "🎥" then
      return pandoc.RawInline("latex", "\\emojivideo{}")
    elseif s == "💄" then
      return pandoc.RawInline("latex", "\\emojimakeup{}")
    elseif s == "🛠" then
      return pandoc.RawInline("latex", "\\emojitool{}")
    elseif s == "🤝" then
      return pandoc.RawInline("latex", "\\emojihandshake{}")
    elseif s:find("&") then
      return pandoc.RawInline("latex", s:gsub("&", "\\&"))
    else
      return el
    end
  end
end

