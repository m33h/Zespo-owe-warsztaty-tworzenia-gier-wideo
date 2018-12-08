dbg = require("debugger")

function inspect(table)
    for k,v in pairs(table) do
       print("\n\n"..k,v.."\n\n")
    end
end