@enum ResponseType RELATIVE ABSOLUTE

type Toggle <: Control
    info::ControlInfo
    onval::Float64
    offval::Float64
    local_off::Bool
end

function Toggle(;offval=0.0, onval=1.0, local_off=false, kwargs...)
    Toggle(ControlInfo(; kwargs...), onval, offval, local_off)
end

typestring(::Toggle, landscape::Bool) = "toggle"

function addxmlinfo!(xml, tog::Toggle)
    set_attribute(xml, "scalef", tog.offval)
    set_attribute(xml, "scalet", tog.onval)
    set_attribute(xml, "local_off", tog.local_off)

    nothing
end

type Label <: Control
    info::ControlInfo
    text::ASCIIString
    textsize::Int
    orientation::Orientation
end

function Label(; text="", textsize=24, orientation=HORIZONTAL, kwargs...)
    Label(ControlInfo(; kwargs...), text, textsize, orientation)
end

function typestring(label::Label, landscape::Bool)
    if landscape
        label.orientation == VERTICAL ? "labelh" : "labelv"
    else
        label.orientation == VERTICAL ? "labelv" : "labelh"
    end
end

function addxmlinfo!(xml, label::Label)
    set_attribute(xml, "text", base64encode(label.text))
    set_attribute(xml, "size", label.textsize)

    nothing
end

type Fader <: Control
    info::ControlInfo
    min::Float64
    max::Float64
    orientation::Orientation
    responsetype::ResponseType
    inverted::Bool
    centered::Bool
end

function Fader(;min=0.0, max=1.0, orientation=HORIZONTAL, responsetype=ABSOLUTE,
          inverted=false, centered=false, kwargs...)
    Fader(ControlInfo(; kwargs...), min, max, orientation, responsetype, inverted, centered)
end

function typestring(fader::Fader, landscape::Bool)
    if landscape
        fader.orientation == VERTICAL ? "faderh" : "faderv"
    else
        fader.orientation == VERTICAL ? "faderv" : "faderh"
    end
end

function addxmlinfo!(xml, fader::Fader)
    set_attribute(xml, "response", lowercase(string(fader.responsetype)))
    set_attribute(xml, "scalef", fader.min)
    set_attribute(xml, "scalet", fader.max)
    set_attribute(xml, "inverted", fader.inverted)
    set_attribute(xml, "centered", fader.centered)

    nothing
end

type Encoder <: Control
    info::ControlInfo
    min::Float64
    max::Float64
end

function Encoder(;min=0.0, max=1.0, kwargs...)
    Encoder(ControlInfo(; kwargs...), min, max)
end

typestring(enc::Encoder, landscape::Bool) = "encoder"

function addxmlinfo!(xml, enc::Encoder)
    set_attribute(xml, "scalef", enc.min)
    set_attribute(xml, "scalet", enc.max)

    nothing
end
