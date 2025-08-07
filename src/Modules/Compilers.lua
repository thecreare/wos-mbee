local CompilersModule = {}
CompilersModule.__index = CompilersModule

type CompilersModule = typeof(setmetatable({} :: {
    _SelectedCompiler: any,
    _Compilers: {any},
}, CompilersModule))

function CompilersModule.GetSelectedCompiler(self: CompilersModule)
    return self._SelectedCompiler
end

function CompilersModule.GetCompilers(self: CompilersModule)
    return self._Compilers
end

function CompilersModule.SelectCompiler(self: CompilersModule, compiler_id: number)
    for i, compiler in self._Compilers do
        compiler.Selected = i == compiler_id
    end
    self._SelectedCompiler = self._Compilers[compiler_id]
end

function CompilersModule.GetComponents(self: CompilersModule): {Configuration}
    return self._SelectedCompiler.Components
end

function CompilersModule.GetShapes(self: CompilersModule): {BasePart}
    return self._SelectedCompiler.Shapes
end

function CompilersModule.GetPartMetadata(self: CompilersModule)
    return self._SelectedCompiler.PartMetadata
end

function CompilersModule.GetConfigData(self: CompilersModule)
    return self._SelectedCompiler.ConfigData
end

function CompilersModule.GetAllMalleability(self: CompilersModule)
    return self._SelectedCompiler.Malleability
end

type CompilerModuleScript = ModuleScript & {
    Components: Folder,
    Shapes: Folder,
    PartMetadata: ModuleScript & {
        Malleability: ModuleScript,
        ConfigData: ModuleScript
    }
}

function CompilersModule.new(compilers_path: Folder)
    local Compilers = {}
    local SelectedCompiler = nil
    for i, comp in compilers_path:GetChildren() :: {CompilerModuleScript} do
        local c = (require)(comp)
        Compilers[i] = c
    
        c.Components = comp.Components:GetChildren()
        c.Shapes = comp.Shapes:GetChildren()
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