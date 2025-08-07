local Mutex = {}
Mutex.__index = Mutex

export type Mutex = typeof(setmetatable({} :: {
    tasks: {thread},
}, Mutex))

function Mutex.new(): Mutex
    local self = setmetatable({
        tasks = {},
    }, Mutex)

    return self
end

--- Yields until the mutex is unlocked, locking it
function Mutex.Lock(self: Mutex)
    table.insert(self.tasks, coroutine.running())
    if #self.tasks > 1 then
        coroutine.yield()
    end
end

--- Unlocks the mutex, allowing it to be locked again
function Mutex.Unlock(self: Mutex)
    -- Remove self from queue of tasks
    local task = table.remove(self.tasks)
    if not task then
        warn("Attempt to unlock not locked mutex")
        return
    end
    
    -- Resume the next task if there is one
    local next_task = self.tasks[1]
    if next_task then
        coroutine.resume(next_task)
    end
end

-- Wrap a function with mutex
function Mutex.Wrap<F>(self: Mutex, fn: F & (...any)->(...any)): F
    return function(...: any)
        self:Lock()
        local results = {pcall(fn, ...)} :: {any}
        self:Unlock()
        if not results[1] then
            error(results[2])
        end
        return table.unpack(results, 2)
    end :: any
end

return Mutex