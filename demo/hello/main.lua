-- Card text is HTML, so escape anything taken from the book.
local function escape(text)
  return (tostring(text):gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#39;",
  }))
end

function before_lookup(ctx)
  return {
    title = "Hello",
    html = "<p>You looked up <b>" .. escape(ctx.word) .. "</b>.</p>",
    footer = "Hello plugin",
  }
end
