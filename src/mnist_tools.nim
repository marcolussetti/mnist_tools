import streams, strutils, endians, os, sequtils, httpclient, sugar
import zip/gzipfiles

type
    MnistImages* = seq[MnistImage]
    MnistImage* = tuple[label: int, image: seq[int]]

const baseUrl = "http://yann.lecun.com/exdb/mnist/"
const files = [
    "train-images-idx3-ubyte.gz",
    "train-labels-idx1-ubyte.gz",
    "t10k-images-idx3-ubyte.gz",
    "t10k-labels-idx1-ubyte.gz"
]


# Utilities
proc readInt32BigEndian(input: Stream): int32 =
    var bytes = input.readInt32
    bigEndian32(addr result, addr bytes)


proc readInt32BigEndianAsInt(input: Stream): int =
    return int(input.readInt32BigEndian)


proc readIntFromIdx(input: Stream): int =
    return int(input.readChar)


# Loader functions
proc mnistLoadLabels(labelFileStream: Stream): seq[int] =
    # Extract metadata about file
    let magicNumber = int(labelFileStream.readInt32BigEndian)
    # assert magicNumber == 2049,
    #     "Incorrect magic number provided! Is this a MNIST labels dataset?"
    let numberLabels = int(labelFileStream.readInt32BigEndian)

    var mnistLabels = newSeq[int]()

    for i in 0..<numberLabels:
        mnistLabels.add(labelFileStream.readIntFromIdx)

    return mnistLabels


proc mnistLoadImages(imageFileStream: Stream): seq[seq[int]] =
    # Extract metadata about file
    let magicNumber = imageFileStream.readInt32BigEndianAsInt
    # assert magicNumber == 2051,
    #     "Incorrect magic number provided! Is this a MNIST dataset?"
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


proc mnistImagesToCsv(images: MnistImages): string =
    let header = lc[ [$i, $j].join("_") | (i <- 0..<28, j <- 0..<28), string]
    result &= "Label," & header.join(",")
    result &= "\n"

    for image in images:
        result &= $image[0] & "," & image[1].join(",")
        result &= "\n"


# Exported functions
proc mnistDownload*(outputDir: string = "") =
    var client = newHttpClient()
    for file in files:
        if not existsFile(outputDir & file):
            echo("Downloading " & baseUrl & file & " ...")
            client.downloadFile(baseUrl & file, outputDir & file)
            assert existsFile(outputDir & file),
                "For some reason file was not downloaded successfully"


proc mnistLoad*(imageFilePath: string, labelFilePath: string): MnistImages =
    if not existsFile(labelFilePath):
        raise newException(IOError,
                "Label path provided does not exist or is not a file.")
    if not existsFile(labelFilePath):
        raise newException(IOError,
                "Path provided does not exist or is not a file.")

    var imageFileStream = newGzFileStream(imageFilePath, fmRead)
    var labelFileStream = newGzFileStream(labelFilePath, fmRead)

    let images = mnistLoadImages(imageFileStream)
    let labels = mnistLoadLabels(labelFileStream)
    assert labels.len == images.len,
        "The length of each file does not match!"

    imageFileStream.close
    labelFileStream.close

    return mnistCombine(labels, images)


proc mnistTrainingData*(sourceDir = ""): MnistImages =
    if not existsFile(sourceDir & files[0]) or not existsFile(
            sourceDir & files[1]):
        mnistDownload(sourceDir)
    return mnistLoad(sourceDir & files[0], sourceDir & files[1])


proc mnistTestData*(sourceDir = ""): MnistImages =
    if not existsFile(sourceDir & files[2]) or not existsFile(
            sourceDir & files[3]):
        mnistDownload(sourceDir)
    return mnistLoad(sourceDir & files[2], sourceDir & files[3])


proc mnistCoarseAsciiImage*(image: seq[int], cols = 28,
        threshold = 50): string =
    for i in 0..<image.len:
        result &= (if image[i] > threshold: "██" else: "  ")
        if i mod cols == 0: result &= "\n"

    result &= "\n"


proc mnistToCsv*(sourceDir = "", outputDir = "") =
    echo "Loading Training Data. This might take a while..."
    let trainingString = mnistImagesToCsv(mnistTrainingData(sourceDir))

    echo "Converting Training data to CSV. This might take a while..."
    var trainingStream = newFileStream(outputDir & "mnist-training.csv",
            fmWrite)
    trainingStream.write(trainingString)
    trainingStream.close

    echo "Loading Test Data. This might take a while..."
    let testString = mnistImagesToCsv(mnistTestData(sourceDir))
    echo "Converting Training data to CSV. This might take a while..."
    var testStream = newFileStream(outputDir & "mnist-test.csv",
            fmWrite)
    testStream.write(testString)
    testStream.close
