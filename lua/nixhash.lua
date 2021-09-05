-- parses wanted: sha256:0000000000000000000000000000000000000000000000000000 into the sha256 only
local function parseline(txt)
  return string.sub(txt, -52, -1)
end
-- runs this command and returns a table of wanted => got hashes
local function run_and_parse(cmd)
  local tempfile = vim.fn.tempname()
  local fullcmd = cmd .. " |& tee >(grep -E '(wanted|got): *sha256:' >" .. vim.fn.shellescape(tempfile) .. ")"
  vim.cmd(":!" .. fullcmd)
  local lines = vim.fn.readfile(tempfile, "", 100)
  local res = {}
  local wanted = nil
  for _, line in ipairs(lines) do
    if string.find(line, "got:") then
      if wanted then
        if res[wanted]
        then print("ignoring duplicate "..wanted)
        else res[wanted] = parseline(line)
        end
        wanted = nil
      else
        error("got: without wanted:")
      end
    else
      if string.find(line, "wanted:") then
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
      local out = vim.api.nvim_exec(":%s/"..pattern.."//gn", true)
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
  vim.api.nvim_buf_call(buffer, function ()
    vim.cmd(":%s/"..pattern.."/"..replacement_pattern.."/")
  end)
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
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "ft") == "nix" then
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
      replace(before, after, buffers[before])
      count_done = count_done + 1
    end
  end
  print(count_done .. " hash replaced")
end
return {
  run_and_fix = run_and_fix
}
