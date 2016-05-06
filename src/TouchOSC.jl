module TouchOSC

export Layout, Page
export Toggle
export VERTICAL, HORIZONTAL
export IPHONE, IPAD, IPHONE5, IPHONE6, IPHONE6PLUS, IPADPRO
export RED, GREEN, BLUE, YELLOW, PURPLE, GRAY, ORANGE, BROWN, PINK
export save

using LightXML
using ZipFile

const TOUCHOSC_FILE_VERSION = 15

# ascii(base64decode("LzEvdGVzdA=="))
# base64encode("/1/test")

@enum Orientation VERTICAL HORIZONTAL

# I haven't checked all these against the editor-generated XML, I'm assuming
# based on checking the first two
@enum LayoutMode IPHONE IPAD IPHONE5 IPHONE6 IPHONE6PLUS IPADPRO

@enum ControlColor RED GREEN BLUE YELLOW PURPLE GRAY ORANGE BROWN PINK

abstract Control

"The properties common to all Controls"
type ControlInfo
    name::ASCIIString
    position::Tuple{Int, Int}
    color::ControlColor
    size::Tuple{Int, Int}
    oscpath::ASCIIString
end

function ControlInfo(; name="", position=(0, 0), color=RED, size=(50, 50), oscpath="")
    ControlInfo(name, position, color, size, oscpath)
end

# create the accessor functions
for prop in [:name, :position, :color, :size, :oscpath]
    @eval $prop(ctrl::Control) = ctrl.info.$prop
end

function pushxml!(pagexml, ctrl::Control, landscape::Bool)
    xml = new_child(pagexml, "control")
    set_attribute(xml, "name", base64encode(name(ctrl)))
    # we need to flip the x and y axes if it's in landscape mode
    set_attribute(xml, "x", position(ctrl)[landscape ? 2 : 1])
    set_attribute(xml, "y", position(ctrl)[landscape ? 1 : 2])
    set_attribute(xml, "w", size(ctrl)[landscape ? 2 : 1])
    set_attribute(xml, "h", size(ctrl)[landscape ? 1 : 2])
    set_attribute(xml, "color", lowercase(string(color(ctrl))))
    if oscpath(ctrl) != ""
        set_attribute(xml, "osc_cs", base64encode(oscpath(ctrl)))
    end
    set_attribute(xml, "type", typestring(ctrl))
    # now add the type-specific info
    addxmlinfo!(xml, ctrl)
end

type Toggle <: Control
    info::ControlInfo
    onval::Float64
    offval::Float64
    local_off::Bool
end

function Toggle(;offval=0.0, onval=1.0, local_off=false, kwargs...)
    Toggle(ControlInfo(;kwargs...), onval, offval, local_off)
end

typestring(::Toggle) = "toggle"

function addxmlinfo!(xml, tog::Toggle)
    set_attribute(xml, "scalef", tog.offval)
    set_attribute(xml, "scalet", tog.onval)
    set_attribute(xml, "local_off", tog.local_off)

    nothing
end

type Page
    name::ASCIIString
    controls::Vector{Control}
end

function Page(;name="", controls=Control[])
    Page(name, controls)
end

function pushxml!(layoutxml, page::Page, landscape::Bool)
    child = new_child(layoutxml, "tabpage")
    set_attribute(child, "name", base64encode(page.name))
    set_attribute(child, "scalef", "0.0")
    set_attribute(child, "scalet", "1.0")

    for control in page.controls
        pushxml!(child, control, landscape)
    end

    child
end

type Layout
    orientation::Orientation
    mode::LayoutMode
    pages::Vector{Page}
end

function Layout(;orientation=VERTICAL, mode=IPHONE, pages=Page[])
    Layout(orientation, mode, pages)
end

function pushxml!(xmldoc, layout::Layout)
    root = create_root(xmldoc, "layout")
    set_attribute(root, "mode", string(Int(layout.mode)))
    # in the XML the string is reversed from what's displayed in the editor
    set_attribute(root, "orientation",
        layout.orientation == VERTICAL ? "horizontal" : "vertical")
    set_attribute(root, "version", TOUCHOSC_FILE_VERSION)

    for page in layout.pages
        pushxml!(root, page, layout.orientation == HORIZONTAL)
    end

    root
end

Base.push!(layout::Layout, page::Page) = push!(layout.pages, page)
Base.push!(page::Page, ctrl::Control) = push!(page.controls, ctrl)

function save(layout::Layout, filename)
    zip = ZipFile.Writer(filename)
    index = ZipFile.addfile(zip, "index.xml")

    xmldoc = XMLDocument()
    pushxml!(xmldoc, layout)
    print(xmldoc)
    write(index, string(xmldoc))
    close(zip)
end

end # module
