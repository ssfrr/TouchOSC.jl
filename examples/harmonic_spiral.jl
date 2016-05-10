using TouchOSC

const mintogsize = 30
const maxtogsize = 50
const minharm = 1
const maxharm = 128
const logmaxharm = log2(maxharm)

layout = Layout(mode=IPAD, orientation=HORIZONTAL)
dims = size(layout)
center = (dims[1]/2, dims[2]/2-5)

mainpage = Page(name="main")

push!(mainpage, Label(text="Root Frequency", size=(750, 30), position=(50, 150), color=GRAY, textsize=24))
push!(mainpage, Label(text="Coarse", size=(150, 50), position=(150, 185), color=BLUE, textsize=32))
push!(mainpage, Encoder(size=(350, 350), position=(50, 250), oscpath="/coarse", color=BLUE, min=-1))
push!(mainpage, Label(text="Fine", size=(150, 50), position=(550, 185), color=GREEN, textsize=32))
push!(mainpage, Encoder(size=(350, 350), position=(450, 250), oscpath="/fine", color=GREEN, min=-1))
push!(mainpage, Label(text="Master", size=(200, 50), position=(800, 40), color=ORANGE, textsize=32))
push!(mainpage, Fader(orientation=VERTICAL, size=(80, 550), position=(865, 110),
                      oscpath="/master", color=ORANGE, responsetype=RELATIVE))
push!(mainpage, Push(size=(45, 45), position=(20, 660), oscpath="/dump", color=RED))
push!(mainpage, Label(size=(200, 45), position=(70, 660), color=RED, text="Dump Settings"))

push!(layout, mainpage)

for pagenum in 1:6
    page = Page(name=string(pagenum))
    push!(layout, page)
    speakernum = pagenum-1

    for harmonic in minharm:maxharm
        # how far along the spiral are we?
        distance = log2(harmonic)
        angle = mod2pi(distance * 2pi)
        radius = distance * 50
        size = round(Int, mintogsize + (1-distance/logmaxharm) * (maxtogsize-mintogsize))
        centerpos = (1.2*radius * sin(angle)+center[1], -radius * cos(angle) + center[2])
        position = (round(Int, centerpos[1]-size/2), round(Int,  centerpos[2] - size/2))
        color = harmonic == 1 ? GREEN : isprime(harmonic) ? BLUE : RED
        push!(page, Fader(name="harm$harmonic", position=position, color=color,
                           size=(size, size),
                           oscpath="/speaker/$speakernum/harm/$harmonic",
                           responsetype=RELATIVE, orientation=VERTICAL))

        position = (round(Int, centerpos[1]-7.5), round(Int, centerpos[2]-7.5))
        push!(page, Led(position=position, color=YELLOW, size=(15, 15),
                        oscpath="/speaker/$speakernum/led/$harmonic"))
    end
    push!(page, Label(text=string(pagenum-1), size=(75, 75), position=(25, 628), color=ORANGE, textsize=64))
    push!(page, Label(text="Level", size=(80, 25), position=(930, 690), color=ORANGE, textsize=14))
    push!(page, Fader(size=(30, 300), position=(955, 380), color=ORANGE,
          orientation=VERTICAL, oscpath="/speaker/$speakernum/level"))
end

save(layout, """$(ENV["HOME"])/Desktop/youngsmodulus_controller.touchosc""")
