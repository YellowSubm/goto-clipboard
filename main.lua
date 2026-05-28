--- @since 25.12.29

local function notify(title, level, content, timeout)
	ya.notify({
		title = title,
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
		if host and host:match("^%a:$") then
			return host .. path:gsub("/", "\\")
		end
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
	s = s:gsub("^%s*cd%s+", "")
	s = strip_quotes(s)
	if s == "" then
		return nil
	end

	if s:match("^file://") then
		s = parse_file_uri(s)
	end

	if ya.target_os() == "windows" then
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

local function compact(s, max)
	s = trim(s):gsub("%s+", " ")
	max = max or 72
	if #s <= max then
		return s
	end

	local head = math.floor((max - 3) / 2)
	local tail = max - 3 - head
	return s:sub(1, head) .. "..." .. s:sub(#s - tail + 1)
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
			local content = trim(text) == "" and "剪贴板为空" or "无有效路径: " .. compact(text)
			return notify("未跳转", "warn", content, 4)
		end

		for _, path in ipairs(paths) do
			if is_dir(path) then
				ya.emit("cd", { path })
				return notify("已跳转", "info", path_name(path), 2)
			end
		end

		local first = paths[1]
		notify("未跳转", "warn", "不是目录: " .. path_name(first) .. "\n" .. compact(text), 4)
	end,
}
