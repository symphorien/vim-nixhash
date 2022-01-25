-- parses wanted: sha256:0000000000000000000000000000000000000000000000000000 into the sha256 only
local function parseline(txt)
  local words = vim.fn.split(txt)
  return words[#words]
end

-- converts the hash to base32
local function toBase32(txt)
  local base32 = vim.fn.system({"nix-hash", "--type", "sha256", "--to-base32", txt})
  local words = vim.fn.split(base32)
  if #words > 1 then error("nix-hash failed: "..base32) end
  local res = words[#words]
  if not string.match(res, '^[0-9a-z]+$') then error("nix-hash returned unexpected result:"..base32) end
  return res
end

-- converts the hash to base16
local function toBase16(txt)
  local base16 = vim.fn.system({"nix-hash", "--type", "sha256", "--to-base16", txt})
  local words = vim.fn.split(base16)
  if #words > 1 then error("nix-hash failed: "..base16) end
  local res = words[#words]
  if not string.match(res, '^[0-9a-f]+$') then error("nix-hash returned unexpected result:"..base16) end
  return res
end

-- converts the hash to base64
-- only uses coreutils and stable nix
local function toBase64(txt)
  local base16 = string.upper(toBase16(txt))
  local cmd = "echo -n "..vim.fn.shellescape(base16).."|basenc -d --base16 | base64"
  local out = vim.fn.system(cmd)
  local words = vim.fn.split(out)
  if #words > 1 then error("failed to convert hash to base64: "..out) end
  local res = words[#words]
  if not string.match(res, '^[0-9A-Za-z+/]+=$') then error("conversion to base64 returned unexpected result:"..out.."end") end
  return res
end

-- runs this command and returns a table of wanted => got hashes
local function run_and_parse(cmd)
  local tempfile = vim.fn.tempname()
  local fullcmd = cmd .. " |& tee >(grep -E '(wanted|got|specified): *sha256' >" .. vim.fn.shellescape(tempfile) .. ")"
  vim.cmd(":!" .. fullcmd)
  local lines = vim.fn.readfile(tempfile, "", 100)
  local res = {}
  local wanted = nil
  for _, line in ipairs(lines) do
    if string.find(line, "got:") then
      if wanted then
        if res[wanted]
        then print("ignoring duplicate "..wanted)
        else
          local replacement = parseline(line)
          res[toBase32(wanted)] = replacement
          res[toBase16(wanted)] = replacement
          res[toBase64(wanted)] = replacement
        end
        wanted = nil
      else
        error("got: without wanted:")
      end
    else
      if string.find(line, "wanted:") or string.find(line, "specified:") then
        if wanted then
          error("two consecutive wanted")
        else
          wanted = parseline(line)
        end
      else
        error("unexpected line "..line)
      end
    end
  end
  return res
end
local match_count = {
  none = 0,
  one = 1,
  multiple = 2
}
-- returns whether this buffer has no, one of several matches for this pattern
local function buffer_match_count(pattern, buffer)
  return vim.api.nvim_buf_call(buffer, function ()
    if vim.fn.search(pattern, "cnw") >= 1 then
      -- this returns a vim error if there is no match
      local out = vim.api.nvim_exec(":%s/"..vim.fn.escape(pattern, "/").."//gn", true)
      if vim.startswith(out, "1 ") then
        return match_count.one
      else
        return match_count.multiple
      end
    else
      return match_count.none
    end
  end)
end
-- replaces this pattern by another in the specified buffer
local function replace(pattern, replacement_pattern, buffer)
  local cmd = ":%s/"..vim.fn.escape(pattern, "/").."/"..vim.fn.escape(replacement_pattern, "/").."/"
  vim.api.nvim_buf_call(buffer, function ()
    vim.cmd(cmd)
  end)
end

-- returns whether this buffer index is a nix buffer
-- detects either ft or extension. ft only works if vim nix is installed it seems
local function is_nix_buffer(buf)
  if vim.api.nvim_buf_get_option(buf, "ft") == "nix" then return true end
  local name = vim.api.nvim_buf_get_name(buf)
  local extension = ".nix"
  return string.sub(name, -#extension) == extension
end
-- runs a command and replaces the hashes accordingly
-- if there is an ambiguity (a hash in several buffer), skip.
local function run_and_fix(cmd)
  local count_done = 0
  local replacements = run_and_parse(cmd)
  -- how many times each wanted hash is present in all loaded buffers
  local counts = {}
  -- one buffer that contains each wanted hash
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and is_nix_buffer(buf) then
      for before, _ in pairs(replacements) do
        local current_count = counts[before] or 0
        if current_count <= match_count.one then
          local count = buffer_match_count(before, buf)
          counts[before] = current_count + count
          if count == match_count.one then
            buffers[before] = buf
          end
        end
      end
    end
  end
  for before, after in pairs(replacements) do
    if counts[before] == match_count.one then
      replace([[\(sha256[-:]\)\?]]..before, after, buffers[before])
      count_done = count_done + 1
    end
  end
  print(count_done .. " hash replaced")
end
return {
  run_and_fix = run_and_fix
}
