local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "mypy",
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "mypy",
        args = function(params)
            return {
                "--hide-error-codes",
                "--hide-error-context",
                "--no-color-output",
                "--show-column-numbers",
                "--show-error-codes",
                "--no-error-summary",
                "--no-pretty",
                "--shadow-file",
                params.bufname,
                params.temp_path,
                params.bufname,
            }
        end,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = h.diagnostics.from_pattern(
            "[^:]+:(%d+):(%d+): (%a+): (.*)  %[([%a-]+)%]", --
            { "row", "col", "severity", "message", "code" },
            {
                severities = {
                    error = h.diagnostics.severities["error"],
                    warning = h.diagnostics.severities["warning"],
                    note = h.diagnostics.severities["information"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
