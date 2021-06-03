local s = require("null-ls.state")
local u = require("null-ls.utils")
local c = require("null-ls.config")

local methods = require("null-ls.methods")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp
local api = vim.api

local function on_init(client)
    handlers.setup_client(client)
    s.initialize(client)
end

local on_exit = function()
    s.reset()
end

local start_client = function()
    s.reset()

    local client_id = lsp.start_client({
        cmd = {
            "nvim",
            "--headless",
            "--noplugin",
            "-c",
            "lua require'null-ls'.start_server()",
        },
        root_dir = vim.fn.getcwd(), -- not relevant yet, but required
        on_init = on_init,
        on_exit = on_exit,
        on_attach = c.get().on_attach,
        name = "null-ls",
        flags = { debounce_text_changes = c.get().debounce },
    })

    -- this completes before the client is initialized
    -- and signals that start_client should not be called again
    s.set({ client_id = client_id })
end

local try_attach = function(bufnr, ft, uri)
    bufnr = bufnr or api.nvim_get_current_buf()
    if not api.nvim_buf_is_loaded(bufnr) or vim.fn.buflisted(bufnr) == 0 then
        return
    end

    -- the event that triggers this function must fire after the buffer's filetype has been set
    ft = ft or api.nvim_buf_get_option(bufnr, "filetype")
    if ft == "" then
        return
    end
    if not u.filetype_matches(c.get().filetypes, ft) then
        return
    end

    if not s.get().client_id then
        start_client()
    end

    s.attach(bufnr, uri)
end

local M = {}

M.start = start_client

M.try_attach = try_attach

-- triggered after dynamically registering sources
M.attach_or_refresh = function()
    local bufnr = api.nvim_get_current_buf()
    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    if ft == "" then
        return
    end

    local uri = vim.uri_from_bufnr(bufnr)
    -- notify client to get diagnostics from new sources
    if s.get().attached[uri] then
        s.notify_client(methods.lsp.DID_CHANGE, { textDocument = { uri = uri } })
        return
    end

    try_attach(bufnr, ft, uri)
end

return M
