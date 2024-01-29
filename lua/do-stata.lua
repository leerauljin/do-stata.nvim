local M = {}

---@class Config
---@field stata_ver "StataBE" | "StataSE" | "StataMP"
M.config = {
  stata_ver = "StataMP"
}

M.get_text = function()
  ---Checks if current mode is visual mode
  local function is_vmode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == 'v' or mode == 'V'
  end

  local line_start = 0
  local line_end = vim.api.nvim_buf_line_count(0)
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  local text = ''

  if is_vmode() then
    -- visual mode need to be exited to update marker
    vim.api.nvim_feedkeys(esc, 'x', false)
    line_start = vim.fn.getpos("'<")[2] - 1
    line_end = vim.fn.getpos("'>")[2]
  end

  local lines = vim.api.nvim_buf_get_lines(0, line_start, line_end, false)

  for _, line in ipairs(lines) do
    text = text .. line .. '\n'
  end

  return text
end

---Write file to a given path
---@param text string Text content to write
---@param filename string File path and name
M.save_file = function(text, filename)
  local file = io.open(filename, "w")
  if file ~= nil then
    file:write(text)
    file:close()
  end
end

---Run do file in Stata (macOS specific)
---@param filename string File path and name
M.run_do = function(filename)
  local output = vim.fn.system {
    'osascript',
    '-e',
    string.format('tell application \"%s\"', M.config.stata_ver),
    '-e',
    'activate',
    '-e',
    string.format('DoCommand \"do %s\"', filename),
    '-e',
    'end tell'
  }
  if string.sub(output, 1, 1) ~= '0' then
    print('Error excuting stata!')
  end
end

---Get content of current buffer (or selected lines) and send to Stata
M.run_line = function()
  local tempname = string.format('%s.do', vim.fn.tempname())
  local text = M.get_text()

  M.save_file(text, tempname)
  M.run_do(tempname)
end

---@param opts Config | nil
M.setup = function(opts)
  local map = vim.keymap.set

  M.config = vim.tbl_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("DoStata", function()
    require("do-stata").run_line()
  end, { nargs = '*', desc = "Run do file in Stata" })


  map("n", "<leader>r", "<cmd>DoStata<cr>")
  map("v", "<leader>r", "<cmd>DoStata<cr>")

end

return M
