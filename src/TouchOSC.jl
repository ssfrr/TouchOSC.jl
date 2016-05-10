module TouchOSC

export Layout, Page
export Led, Push, Toggle, Fader, Label, Encoder
export VERTICAL, HORIZONTAL
export IPHONE, IPAD, IPHONE5, IPHONE6, IPHONE6PLUS, IPADPRO
export RED, GREEN, BLUE, YELLOW, PURPLE, GRAY, ORANGE, BROWN, PINK
export RELATIVE, ABSOLUTE
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
for prop in [:name, :position, :color, :oscpath]
    @eval $prop(ctrl::Control) = ctrl.info.$prop
end

# size is special because we're extending Base.size
Base.size(ctrl::Control) = ctrl.info.size

type Page
    name::ASCIIString
    controls::Vector{Control}
end

function Page(;name="", controls=Control[])
    Page(name, controls)
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
        # we have to give the layout because some of the XML generation
        # varies depending on the layout
        pushxml!(root, page, layout)
    end

    root
end

# needs to include the layout object so we can inspect it during XML generation
# for some of the controls
function pushxml!(layoutxml, page::Page, layout::Layout)
    child = new_child(layoutxml, "tabpage")
    set_attribute(child, "name", base64encode(page.name))
    set_attribute(child, "scalef", "0.0")
    set_attribute(child, "scalet", "1.0")

    for control in page.controls
        pushxml!(child, control, layout)
    end

    child
end

# transforms an XY position and size into the correct coordinates for the XML,
# which involves flipping X and Y axes in landscape mode, and inverting the X
# axis. This means that when we create the objects we can use locations that
# match what we'd see in the editor, and they'll end up in the right places
function transform(layout::Layout, pos, siz)
    if layout.orientation == VERTICAL
        return pos, siz
    end
    # take into account the space for the top bar
    screenheight = size(layout)[2] - 40

    (screenheight - pos[2] - siz[2], pos[1]), (siz[2], siz[1])
end

function pushxml!(pagexml, ctrl::Control, layout::Layout)
    landscape = layout.orientation == HORIZONTAL
    layoutpos, layoutsize = transform(layout, position(ctrl), size(ctrl))
    xml = new_child(pagexml, "control")
    set_attribute(xml, "name", base64encode(name(ctrl)))
    set_attribute(xml, "x", layoutpos[1])
    set_attribute(xml, "y", layoutpos[2])
    set_attribute(xml, "w", layoutsize[1])
    set_attribute(xml, "h", layoutsize[2])
    set_attribute(xml, "color", lowercase(string(color(ctrl))))
    if oscpath(ctrl) != ""
        set_attribute(xml, "osc_cs", base64encode(oscpath(ctrl)))
    end
    set_attribute(xml, "type", typestring(ctrl, landscape))
    # now add the type-specific info
    addxmlinfo!(xml, ctrl)
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

const layoutsizes = [
    (480, 320), # IPHONE
    (1024, 768), # IPAD
    (568, 320), # IPHONE5
    (667, 375), # IPHONE6
    (736, 414), # IPHONE6PLUS
    (1366, 1024) # IPADPRO
]
function Base.size(layout::Layout)
    dims = layoutsizes[Int(layout.mode)+1]

    layout.orientation == HORIZONTAL ? dims : (dims[2], dims[1])
end

include("controls.jl")

end # module
