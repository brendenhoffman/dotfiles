local SIX_MONTHS = 6 * 30 * 24 * 3600

local function unescape(s)
  return s:gsub("&gt;", ">")
          :gsub("&lt;", "<")
          :gsub("&amp;", "&")
          :gsub("&quot;", '"')
          :gsub("&#39;", "'")
end

-- single-quote for safe interpolation into shell commands
local function shquote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function check_arch_news()
  local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yay"
  local seen_file = state_dir .. "/news-last-read"
  os.execute("mkdir -p " .. shquote(state_dir))

  local last_read = 0
  local f = io.open(seen_file, "r")
  if f then
    last_read = tonumber(f:read("*l")) or 0
    f:close()
  end

  local handle = io.popen("curl -sf --max-time 5 https://archlinux.org/feeds/news/")
  if not handle then return end
  local rss = handle:read("*a")
  handle:close()
  if not rss or rss == "" then return end

  local now = os.time()
  local cutoff = math.max(last_read, now - SIX_MONTHS)
  local unread = {}

  for item in rss:gmatch("<item>(.-)</item>") do
    local title   = item:match("<title>([^<]+)</title>")
    local pubdate = item:match("<pubDate>([^<]+)</pubDate>")
    local link    = item:match("<link>([^<]+)</link>")
    if title and pubdate then
      local ts_h = io.popen("date -d " .. shquote(pubdate) .. " +%s 2>/dev/null")
      local ts = tonumber(ts_h and ts_h:read("*l")) or 0
      if ts_h then ts_h:close() end

      if ts > cutoff then
        local date_h = io.popen("date -d " .. shquote(pubdate) .. " '+%Y-%m-%d' 2>/dev/null")
        local date_str = (date_h and date_h:read("*l")) or pubdate
        if date_h then date_h:close() end

        table.insert(unread, {
          ts    = ts,
          title = unescape(title),
          link  = link,
          date  = date_str,
        })
      end
    end
  end

  if #unread == 0 then return end

  table.sort(unread, function(a, b) return a.ts > b.ts end)

  io.write("\n\27[33m-> Unread Arch Linux news:\27[0m\n")
  for _, item in ipairs(unread) do
    io.write("  \27[33m•\27[0m " .. item.date .. "  " .. item.title .. "\n")
    if item.link and item.link ~= "" then
      io.write("    " .. item.link .. "\n")
    end
  end

  io.write("\nPress Enter to continue, Ctrl-C to abort: ")
  io.flush()
  local line = io.read("*l")
  if line == nil then
    yay.abort("aborted on closed stdin")
  end

  local wf = io.open(seen_file, "w")
  if wf then wf:write(tostring(now) .. "\n"); wf:close() end
end

yay.create_autocmd("UpgradeSelect", {
  desc = "show unread Arch news before upgrade",
  callback = function(_)
    check_arch_news()
    return { exclude = {}, skip_menu = false }
  end,
})

-- suspicious package: warn and confirm
yay.create_autocmd("AURPreInstall", {
  desc = "flag suspicious PKGBUILD patterns",
  callback = function(event)
    local pkgbuild = event.data.pkgbuild
    local hits = {}

    local checks = {
      { pattern = "curl.+[|>].+sh",      label = "curl pipe to shell" },
      { pattern = "wget.+[|>].+sh",      label = "wget pipe to shell" },
      { pattern = "base64%s+%-d",         label = "base64 decode" },
      { pattern = "eval%s*%(",            label = "eval()" },
      { pattern = "ifunc",                label = "GNU ifunc resolver" },
      { pattern = "test%s+%-n%s+.TRAVIS", label = "CI environment check" },
      { pattern = "test%s+%-n%s+.GITHUB", label = "CI environment check" },
    }

    for _, check in ipairs(checks) do
      if pkgbuild:match(check.pattern) then
        table.insert(hits, check.label)
      end
    end

    local age_days = (os.time() - event.data.last_modified) / 86400
    if age_days < 7 and pkgbuild:match("%.install") then
      table.insert(hits, "install script in package less than 7 days old")
    end

    if #hits == 0 then return end

    yay.log.warn(event.match .. ": suspicious patterns detected:")
    for _, h in ipairs(hits) do
      yay.log.warn("  !", h)
    end

    io.write("\nInstall " .. event.match .. " anyway? [y/N] ")
    io.flush()
    local answer = io.read("*l")
    if not answer or (answer:lower() ~= "y") then
      yay.abort(event.match .. ": cancelled by user")
    end
  end,
})
