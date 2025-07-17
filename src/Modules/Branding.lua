local Constants = require(script.Parent.Constants)

if Constants.IS_LOCAL then
    -- Developer environment branding
    return {
        NAME = "Model Builder: Edited Edited [DEV]",
        NAME_ABBREVIATION = "MBEE_DEV",
    }
else
    -- Production branding
    return {
        NAME = "Model Builder: Edited Edited",
        NAME_ABBREVIATION = "MBEE",
    }
end