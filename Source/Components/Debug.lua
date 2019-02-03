dbg = require("debugger")

counter = 0

function inspect(userdata)
    print(getmetatable(userdata))
end

function p(userdata)
    for k,v in pairs(getmetatable(userdata)) do
        print("\n\n"..k,v.."\n\n")
    end
end
