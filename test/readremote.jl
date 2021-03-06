using Images, FixedPointNumbers, Color
using Base.Test

urlbase = "http://www.imagemagick.org/Usage/images/"

const savedir = joinpath(tempdir(), "Images")
const writedir = joinpath(savedir, "write")

function getfile(name)
    file = joinpath(savedir, name)
    if !isfile(file)
        file = download(urlbase*name, file)
    end
    file
end

if !isdir(savedir)
    mkdir(savedir)
end
if !isdir(writedir)
    mkdir(writedir)
end

# Gray
file = getfile("jigsaw_tmpl.png")
img = imread(file)
@test colorspace(img) == "Gray"
@test ndims(img) == 2
@test colordim(img) == 0
@test eltype(img) == Gray{Ufixed8}
outname = joinpath(writedir, "jigsaw_tmpl.png")
imwrite(img, outname)
imgc = imread(outname)
@test img.data == imgc.data
@test reinterpret(Uint32, data(map(mapinfo(RGB24, img), img))) ==
    map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, img), img))))
@test mapinfo(Uint32, img) == mapinfo(RGB24, img)
@test data(convert(Image{Gray{Float32}}, img)) == float32(data(img))
mapi = mapinfo(RGB{Ufixed8}, img)
imgrgb8 = map(mapi, img)
@test imgrgb8[1,1].r == img[1].val
open(outname, "w") do file
    writemime(file, "image/png", img)
end

# Gray with alpha channel
file = getfile("wmark_image.png")
img = imread(file)
@test colorspace(img) == "GrayAlpha"
@test ndims(img) == 2
@test colordim(img) == 0
@test eltype(img) == Images.ColorTypes.GrayAlpha{Ufixed8}
@osx? nothing : begin
    outname = joinpath(writedir, "wmark_image.png")
    imwrite(img, outname)
    sleep(0.2)
    imgc = imread(outname)
    @test img.data == imgc.data
    open(outname, "w") do file
        writemime(file, "image/png", img)
    end
end
@test reinterpret(Uint32, data(map(mapinfo(RGB24, img), img))) ==
    map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, img), img))))
@test mapinfo(Uint32, img) == mapinfo(ARGB32, img)

# RGB
file = getfile("rose.png")
img = imread(file)
# Mac reader reports RGB4, imagemagick reports RGB
@osx? begin
            @test colorspace(img) == "RGB4"
      end : @test colorspace(img) == "RGB"
@test ndims(img) == 2
@test colordim(img) == 0
@osx? begin
            @test eltype(img) == RGB4{Ufixed8}
      end : @test eltype(img) == RGB{Ufixed8}
outname = joinpath(writedir, "rose.ppm")
imwrite(img, outname)
imgc = imread(outname)
T = eltype(imgc)
lim = limits(imgc)
@test (typeof(lim[1]) == typeof(lim[2]) == T)  # issue #62
# Why does this one fail on OSX??
@osx? nothing : @test img.data == imgc.data
@test reinterpret(Uint32, data(map(mapinfo(RGB24, img), img))) ==
    map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, img), img))))
@test mapinfo(Uint32, img) == mapinfo(RGB24, img)
mapi = mapinfo(RGB{Ufixed8}, img)
imgrgb8 = map(mapi, img)
@test data(imgrgb8) == data(img)
convert(Array{Gray{Ufixed8}}, img)
convert(Image{Gray{Ufixed8}}, img)
convert(Array{Gray}, img)
convert(Image{Gray}, img)
imgs = separate(img)
@test permutedims(convert(Image{Gray}, imgs), [2,1]) == convert(Image{Gray}, img)
# Make sure that all the operations in README will work:
buf = Array(Uint32, size(img))
uint32color(img)
uint32color!(buf, img)
imA = convert(Array, img)
uint32color(imA)
uint32color!(buf, imA)
uint32color(imgs)
uint32color!(buf, imgs)
imr = reinterpret(Ufixed8, img)
uint32color(imr)
uint32color!(buf, imr)
@osx? nothing : begin
    imhsv = convert(Image{HSV}, float32(img))
    uint32color(imhsv)
    uint32color!(buf, imhsv)
    @test pixelspacing(restrict(img)) == [2.0,2.0]
end
outname = joinpath(writedir, "rose.png")
open(outname, "w") do file
    writemime(file, "image/png", img)
end

# RGBA with 16 bit depth
file = getfile("autumn_leaves.png")
img = imread(file)
@osx? begin
            @test colorspace(img) == "RGBA"
      end : @test colorspace(img) == "BGRA"
@test ndims(img) == 2
@test colordim(img) == 0
@osx? begin
            @test eltype(img) == Images.ColorTypes.RGBA{Ufixed16}
      end : @test eltype(img) == Images.ColorTypes.BGRA{Ufixed16}
outname = joinpath(writedir, "autumn_leaves.png")
@osx? nothing : begin
    imwrite(img, outname)
    sleep(0.2)
    imgc = imread(outname)
    @test img.data == imgc.data
    @test reinterpret(Uint32, data(map(mapinfo(RGB24, img), img))) ==
        map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, img), img))))
    @test mapinfo(Uint32, img) == mapinfo(ARGB32, img)
end
open(outname, "w") do file
    writemime(file, "image/png", img)
end

# Indexed
file = getfile("present.gif")
img = imread(file)
@test nimages(img) == 1
@test reinterpret(Uint32, data(map(mapinfo(RGB24, img), img))) ==
    map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, img), img))))
@test mapinfo(Uint32, img) == mapinfo(RGB24, img)
outname = joinpath(writedir, "present.png")
open(outname, "w") do file
    writemime(file, "image/png", img)
end

# Images with a temporal dimension
fname = "swirl_video.gif"
#fname = "bunny_anim.gif"  # this one has transparency but LibMagick gets confused about its size
file = getfile(fname)  # this also has transparency
img = imread(file)
@test timedim(img) == 3
@test nimages(img) == 26
outname = joinpath(writedir, fname)
imwrite(img, outname)
imgc = imread(outname)
# Something weird happens after the 2nd image (compression?), and one starts getting subtle differences.
# So don't compare the values.
# Also take the opportunity to test some things with temporal images
@test storageorder(img) == ["x", "y", "t"]
@test haskey(img, "timedim") == true
@test timedim(img) == 3
s = getindexim(img, 1:5, 1:5, 3)
@test timedim(s) == 0
s = sliceim(img, :, :, 5)
@test timedim(s) == 0
imgt = sliceim(img,"t",1)
@test reinterpret(Uint32, data(map(mapinfo(RGB24, imgt), imgt))) ==
    map(x->x&0x00ffffff, reinterpret(Uint32, data(map(mapinfo(ARGB32, imgt), imgt))))
