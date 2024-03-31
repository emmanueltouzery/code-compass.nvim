local compass_java = require('java.compass_java')
local tests = require('tests.tests')

local function find_buf_for_fname(fname)
  for i, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == fname then
      return bufnr
    end
  end
  return nil
end

local function find_local_declarations()
  local matches = {}
  if vim.bo.filetype == 'java' then
    matches = compass_java.find_local_declarations()
  end

  local filtered_matches = {}
  local cur_line = vim.fn.line('.')
  -- keep only matches up to the current row (cannot use variables
  -- defined later on), and keep only the last one such (the same
  -- variable name can be used multiple times in the current file, we
  -- want the latest declaration before the current line)
  local latest_match = nil
  for _, match in ipairs(matches) do
    if match.lnum <= cur_line then
      latest_match = match
    else
      break
    end
  end
  if latest_match ~= nil then
    return { latest_match }
  else
    return {}
  end
end

local function picker_finish(matches)
  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.ERROR)
  elseif #matches == 1 then
    local fbuf = matches[1].bufnr or find_buf_for_fname(matches[1].path)
    if fbuf ~= nil then
      vim.api.nvim_win_set_buf(0, fbuf)
    else
      vim.cmd(":e " .. matches[1].path)
    end
    vim.fn.setpos('.', {0, matches[1].lnum, matches[1].col+1, 0})
    vim.cmd[[ norm! zz]]
  else
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")
    local Str = require'plenary.strings'
    local opts = {}

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 35, },
        { remaining = true },
      },
    }
    local make_display = function(entry)
      return displayer {
        { Str.truncate(entry.path, 35, "…", -1), "TelescopeResultsIdentifier" },
        { entry.line, "Special" },
      }
    end

    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = matches,
        entry_maker = function(entry)
          entry.name = entry.fname
          entry.ordinal = entry.fname
          entry.display = make_display
          return entry
        end,
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
    }):find()
  end
end

--- https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/3
---@param str string
---@param i integer
---@param j? integer
---@return string
local function str_sub(str, i, j)
    local length = vim.str_utfindex(str)
    if i < 0 then i = i + length + 1 end
    if (j and j < 0) then j = j + length + 1 end
    local u = (i > 0) and i or 1
    local v = (j and j <= length) and j or length
    if (u > v) then return "" end
    local s = vim.str_byteindex(str, u - 1)
    local e = vim.str_byteindex(str, v)
    return str:sub(s + 1, e)
end

local function code_compass_picker(query, title, get_field_access_query, opts)
  local cwd = vim.fn.getcwd()
  local line_in_result = 1
  local fname, lnum_str, col_str
  local matches = {}
  vim.fn.jobstart(query, {
    cwd = cwd,
    on_stdout = vim.schedule_wrap(function(j, output)
      -- TODO probably switch to JSON parsing
      for _, line in ipairs(output) do
        if #line > 0 then
          if line_in_result == 1 then
            -- help[query], skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 2 then
            fname, lnum_str, col_str = line:gmatch("%.([^:]+):([^:]+):([^:]+)")()
            line_in_result = line_in_result + 1
          elseif line_in_result == 3 then
            -- blank, skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 4 then
            -- line contents? bunch of ^^^ under the proper line
            if line:match("%^%^") then
              line_in_result = line_in_result + 1
              table.insert(matches, {
                lnum = tonumber(lnum_str),
                col = tonumber(col_str),
                path = cwd .. '/' .. fname,
                fname = fname,
                line = line_contents
              })
            else
              line_contents = str_sub(line, 7)
            end
          elseif line:match("help%[") then
            line_in_result = 2
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      if #matches == 0 then
        -- couldn't find global declarations, could be a local variable
        -- or a field of the current class
        matches = find_local_declarations()
      end
      if #matches == 0 and get_field_access_query ~= nil then
        -- still couldn't find anything. it could be accessing a field on
        -- another class (for instance a public final field)
        -- i don't like to check that too early, because i could grab
        -- a field on a completely unrelated class.. but if nothing else
        -- worked, let's try this now
        code_compass_picker(get_field_access_query(), title, nil, opts)
        return
      end
      if opts ~= nil and opts.matches_callback ~= nil then
        opts.matches_callback(matches)
      else
        picker_finish(matches)
      end
    end)
  })
end

local function find_references(opts)
  local word = vim.fn.expand('<cword>')

  local query = nil
  local get_field_access_query = nil
  if vim.bo.filetype == 'java' then
    get_field_access_query = compass_java.get_field_access_query
    query = compass_java.get_references_query()
  end

  if query ~= nil then
    -- pre-filter the files to process with rg for speed
    code_compass_picker([[ast-grep scan --inline-rules ']] .. query
      ..  [[' $(rg -l ]] .. word .. [[ . | tr '\n' ' ')]], "References", get_field_access_query, opts)
  end
end

local function find_definition(opts)
  local word = vim.fn.expand('<cword>')

  local query = nil
  local get_field_access_query = nil
  if vim.bo.filetype == 'java' then
    get_field_access_query = compass_java.get_field_access_query
    query = compass_java.get_definition_query()
  end

  if query ~= nil then
    -- pre-filter the files to process with rg for speed
    code_compass_picker([[ast-grep scan --inline-rules ']] .. query
      ..  [[' $(rg -l ]] .. word .. [[ . | tr '\n' ' ')]], "Definitions", get_field_access_query, opts)
  end
end


return {
  find_references = find_references,
  find_definition = find_definition,
  run_tests = tests.run_tests,
}
