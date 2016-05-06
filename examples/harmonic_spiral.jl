using TouchOSC

layout = Layout(mode=IPAD, orientation=HORIZONTAL)
page1 = Page(name="1")
push!(layout, page1)

center = (1024/2, 768/2-50)
for harmonic in 1:128
    # how far along the spiral are we?
    distance = log2(harmonic)
    angle = mod2pi(distance * 2pi)
    radius = distance * 50
    position = (round(Int, radius * sin(angle)+center[1]), round(Int, radius * cos(angle) + center[2]))
    color = harmonic == 1 ? GREEN : isprime(harmonic) ? BLUE : RED
    tog = Toggle(name="harm$harmonic", position=position, color=color, size=(30, 30), oscpath="/harm/$harmonic")
    push!(page1, tog)
end

save(layout, """$(ENV["HOME"])/Desktop/testlayout.touchosc""")
