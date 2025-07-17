local CompilersModule = {}
CompilersModule.__index = CompilersModule

function CompilersModule:GetSelectedCompiler()
    return self._SelectedCompiler
end

function CompilersModule:GetCompilers()
    return self._Compilers
end

function CompilersModule:SelectCompiler(compiler_id: number)
    for i, compiler in self._Compilers do
        compiler.Selected = i == compiler_id
    end
    self._SelectedCompiler = self._Compilers[compiler_id]
end

function CompilersModule:GetComponents(): {Configuration}
    return self._SelectedCompiler.Components
end

function CompilersModule:GetPartMetadata()
    return self._SelectedCompiler.PartMetadata
end

function CompilersModule:GetConfigData()
    return self._SelectedCompiler.ConfigData
end

function CompilersModule:GetAllMalleability()
    return self._SelectedCompiler.Malleability
end

function CompilersModule.new(compilers_path: Folder)
    local Compilers = {}
    local SelectedCompiler = nil
    for i, comp in pairs(compilers_path:GetChildren()) do
        local c = (require)(comp)
        Compilers[i] = c
    
        c.Components = comp.Components:GetChildren()
        c.PartMetadata = (require)(comp.PartMetadata)
        c.Malleability = (require)(comp.PartMetadata.Malleability)
        c.ConfigData = (require)(comp.PartMetadata.ConfigData)
        c.Version = comp.Name
    
        if Compilers[i].Default == true and not SelectedCompiler then
            c.Selected = true
            SelectedCompiler = c
        end
    end

    return setmetatable({
        _Compilers = Compilers,
        _SelectedCompiler = SelectedCompiler,
    }, CompilersModule)
end

-- I'm tired, I didn't think this through
return CompilersModule.new(script.Parent.Parent.Compilers)
-- return CompilersModule