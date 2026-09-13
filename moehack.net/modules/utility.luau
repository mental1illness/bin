local Utility = {}

Utility.EasingStyle = {
    Sine = function(t)
        return 1 - math.cos(t * math.pi * 0.5)
    end,

    Quad = function(t)
        return t * t
    end,

    Cubic = function(t)
        return t * t * t
    end,

    Quart = function(t)
        return t * t * t * t
    end,

    Quint = function(t)
        return t * t * t * t * t
    end,

    Exponential = function(t)
        return t == 0 and 0 or 2 ^ (10 * (t - 1))
    end,

    Circular = function(t)
        return 1 - math.sqrt(1 - t * t)
    end,

    Linear = function(t)
        return t
    end,
}

return Utility