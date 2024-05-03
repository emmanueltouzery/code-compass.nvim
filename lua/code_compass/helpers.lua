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

local function find_buf_for_fname(fname)
  for i, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == fname then
      return bufnr
    end
  end
  return nil
end

local function run_and_parse_ast_grep(word, queries, opts, run_finish)
  local cwd = vim.fn.getcwd()
  local line_in_result = 1
  local fname, lnum_str, col_str, query_name
  local matches = {}
  local search_list = (opts and opts.search_list) or ([[$(rg -l ]] .. word .. [[ . | tr '\n' ' ')]])
  -- pre-filter the files to process with rg for speed
  local command = [[ast-grep scan --inline-rules ']] .. queries[1] .. "' "  .. search_list
  vim.fn.jobstart(command, {
    cwd = cwd,
    on_stdout = vim.schedule_wrap(function(j, output)
      -- TODO probably switch to JSON parsing
      for _, line in ipairs(output) do
        if #line > 0 then
          if line_in_result == 1 then
            if line:match("^help%[") then
              query_name = line:gsub("^help%[", ""):gsub("%]: ", "")
            end
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
                line = line_contents,
                query_name = query_name
              })
            else
              line_contents = str_sub(line, 7):gsub("╭", "")
            end
          elseif line:match("help%[") then
            query_name = line:gsub("^help%[", ""):gsub("%]: ", "")
            line_in_result = 2
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      if #matches == 0 and #queries > 1 then
        -- try the next possible query
        table.remove(queries, 1)
        run_and_parse_ast_grep(word, queries, opts, run_finish)
      else
        run_finish(matches)
      end
    end)
  })
end

local function picker_finish(matches)
  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.ERROR)
  elseif #matches == 1 then
    vim.cmd[[normal! m']] -- save the position for jump history
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
      prompt_title = "Definitions",
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

return {
  str_sub = str_sub,
  find_buf_for_fname = find_buf_for_fname,
  run_and_parse_ast_grep = run_and_parse_ast_grep,
  picker_finish = picker_finish,
}
