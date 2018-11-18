import streams, strutils, endians, os, sequtils, httpclient
import zip/gzipfiles

type
    MnistImages = seq[MnistImage]
    MnistImage = tuple[label: int, image: seq[int]]

const baseUrl = "http://yann.lecun.com/exdb/mnist/"
const files = [
    "train-images-idx3-ubyte.gz",
    "train-labels-idx1-ubyte.gz",
    "t10k-images-idx3-ubyte.gz",
    "t10k-labels-idx1-ubyte.gz"
]

proc mnistDownload*(outputDir: string = "") =
    var client = newHttpClient()
    for file in files:
        if not existsFile(outputDir & file):
            echo("Downloading " & baseUrl & file & " ...")
            client.downloadFile(baseUrl & file, outputDir & file)
            assert existsFile(outputDir & file),
                "For some reason file was not downloaded successfully"

proc readInt32BigEndian(input: Stream): int32 =
    var bytes = input.readInt32
    bigEndian32(addr result, addr bytes)

proc readInt32BigEndianAsInt(input: Stream): int =
    return int(input.readInt32BigEndian)

proc readIntFromIdx(input: Stream): int =
    return int(input.readChar)

proc mnistLoadLabels(labelFileStream: Stream): seq[int] =
    # Extract metadata about file
    let magicNumber = int(labelFileStream.readInt32BigEndian)
    assert magicNumber == 2049,
        "Incorrect magic number provided! Is this a MNIST labels dataset?"
    let numberLabels = int(labelFileStream.readInt32BigEndian)

    var mnistLabels = newSeq[int]()

    for i in 0..<numberLabels:
        mnistLabels.add(labelFileStream.readIntFromIdx)

    return mnistLabels

proc mnistLoadImages(imageFileStream: Stream): seq[seq[int]] =
    # Extract metadata about file
    let magicNumber = imageFileStream.readInt32BigEndianAsInt
    assert magicNumber == 2051,
        "Incorrect magic number provided! Is this a MNIST dataset?"
    let numberImages = imageFileStream.readInt32BigEndianAsInt
    let rowsInImage = imageFileStream.readInt32BigEndianAsInt
    let columnsInImage = imageFileStream.readInt32BigEndianAsInt
    let pixelsInImage = rowsInImage * columnsInImage

    var mnistImages = newSeq[seq[int]]()

    for i in 0..<numberImages:
        var image = newSeq[int]()
        for j in 0..<pixelsInImage:
            image.add(imageFileStream.readIntFromIdx)
        mnistImages.add(image)

    return mnistImages

proc mnistCombine(labels: seq[int], images: seq[seq[int]]): MnistImages =
    var minLen = min(labels.len, images.len)
    newSeq(result, minLen)
    for i in 0..<minLen:
        result[i] = (label: labels[i], image: images[i])


proc mnistLoad*(imageFilePath: string, labelFilePath: string,
        gunzipped: bool = true): MnistImages =
    if not existsFile(labelFilePath):
        raise newException(IOError,
                "Label path provided does not exist or is not a file.")
    if not existsFile(labelFilePath):
        raise newException(IOError,
                "Path provided does not exist or is not a file.")

    var imageFileStream, labelFileStream: Stream

    if gunzipped:
        imageFileStream = newGzFileStream(imageFilePath)
        labelFileStream = newGzFileStream(labelFilePath)
    else:
        imageFileStream = newFileStream(imageFilePath, fmRead)
        labelFileStream = newFileStream(labelFilePath, fmRead)

    let images = mnistLoadImages(imageFileStream)
    let labels = mnistLoadLabels(labelFileStream)
    assert labels.len == images.len,
        "The length of each file does not match!"

    imageFileStream.close
    labelFileStream.close

    return mnistCombine(labels, images)


proc mnistTrainingData*(sourceDir: string = ""): MnistImages =
    if not existsFile(sourceDir & files[0]) or not existsFile(
            sourceDir & files[1]):
        mnistDownload(sourceDir)
    return mnistLoad(sourceDir & files[0], sourceDir & files[1])


proc mnistTestData*(sourceDir: string = ""): MnistImages =
    if not existsFile(sourceDir & files[2]) or not existsFile(
            sourceDir & files[3]):
        mnistDownload(sourceDir)
    return mnistLoad(sourceDir & files[2], sourceDir & files[3])


proc mnistCoarseAsciiImage*(image: seq[int], cols: int = 28,
        threshold: int = 50): string =
    for i in 0..<image.len:
        result &= (if image[i] > threshold: "██" else: "  ")
        if i mod cols == 0: result &= "\n"

    result &= "\n"
