--- @since 25.12.29

local function notify(level, content, timeout)
	ya.notify({
		title = "goto-clipboard",
		content = content,
		timeout = timeout or 4,
		level = level,
	})
end

local function trim(s)
	return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function strip_quotes(s)
	s = trim(s)
	local first, last = s:sub(1, 1), s:sub(-1)
	if (first == '"' and last == '"') or (first == "'" and last == "'") then
		return s:sub(2, -2)
	end
	return s
end

local function uri_decode(s)
	return (s:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function parse_file_uri(s)
	s = uri_decode(s)
	if ya.target_os() == "windows" then
		local host, path = s:match("^file://([^/]+)(/.+)$")
		if host and host ~= "" and host ~= "localhost" then
			return "\\\\" .. host .. path:gsub("/", "\\")
		end

		s = s:gsub("^file://localhost/", "")
		s = s:gsub("^file:///", "")
		s = s:gsub("^file://", "")
		return s:gsub("/", "\\")
	end

	return s:gsub("^file://[^/]*", "")
end

local function normalize_path(s)
	s = strip_quotes(s)
	if s == "" then
		return nil
	end

	if s:match("^file://") then
		s = parse_file_uri(s)
	end

	if ya.target_os() == "windows" then
		s = s:gsub("^%s*cd%s+", "")
		s = strip_quotes(s)
		if s:match("^%a:[/\\]") or s:match("^\\\\") then
			return s:gsub("/", "\\")
		end
	else
		local home = os.getenv("HOME")
		if home and s:sub(1, 2) == "~/" then
			s = home .. s:sub(2)
		end
		if s:sub(1, 1) == "/" then
			return s
		end
	end

	return nil
end

local function paths_from_text(text)
	local paths = {}
	for line in tostring(text or ""):gmatch("[^\r\n]+") do
		local path = normalize_path(line)
		if path then
			paths[#paths + 1] = path
		end
	end
	return paths
end

local function path_name(path)
	return path:match("[^/\\]+$") or path
end

local function is_dir(path)
	local _, err = fs.read_dir(Url(path), { limit = 1, resolve = true })
	return err == nil
end

return {
	entry = function()
		local text = ya.clipboard() or ""
		local paths = paths_from_text(text)
		if #paths == 0 then
			local preview = trim(text) == "" and "剪贴板为空" or trim(text):gsub("%s+", " "):sub(1, 120)
			return notify("warn", "剪贴板里没有可识别的路径\n" .. preview, 5)
		end

		for _, path in ipairs(paths) do
			if is_dir(path) then
				ya.emit("cd", { path })
				return notify("info", "已跳转到: " .. path, 2.5)
			end
		end

		local first = paths[1]
		notify("warn", table.concat({
			"剪贴板路径不是可跳转目录，未跳转",
			"名称: " .. path_name(first),
			"路径: " .. first,
		}, "\n"), 6)
	end,
}
