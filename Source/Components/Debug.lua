dbg = require("debugger")

function inspect(table)
    for k,v in pairs(table) do
       print("\n\n"..k,v.."\n\n")
    end
end

function p(userdata)
    for k,v in pairs(getmatetable(userdata)) do
        print("\n\n"..k,v.."\n\n")
    end
end