# MNIST Tools

## Installation

```sh
nimble install https://github.com/marcolussetti/mnist_tools
```


## API

This libraries provides 6 functions:

```nim
# Loads Training Data into a sequence of MnistImage
# Downloads the files if not present in source directory
proc mnistTrainingData*(sourceDir: string = ""): seq[tuple[a: int, b: seq[int]]]

# Loads Training Data into a sequence of MnistImage
# Downloads the files if not present in source directory
proc mnistTestData*(sourceDir: string = ""): seq[tuple[a: int, b: seq[int]]]

# Returns a string visualization of an image, showing items above the threshold
proc mnistCoarseAsciiImage*(image: seq[int], cols: int = 28, threshold: int = 50): string

# Allows for manually specifying paths to load
proc mnistLoad*(imageFilePath: string, labelFilePath: string): seq[tuple[a: int, b: seq[int]]]

# Manually request download of MNIST files to specified directory
proc mnistDownload*(outputDir: string = "")

# Convert the datasets to CSV
proc mnistToCsv*(sourceDir = "", outputDir = "")
```

## Examples

### Loading data

Provides a very coarse ascii print of the image as such:
```nim
import mnist_tools
# Will automatically download in local directory or other provided path
let mnistTraining = mnistTrainingData()
let mnistTest = mnistTestData()

echo mnistTraining[7].image.mnistCoarseAsciiImage # Should print a "3"
```

### Exporting to CSV
If all you need is the MNIST dataset as csvs, you can create a nim file with just a call to the function and then run it:

```nim
import mnist_tools

mnistToCsv()
```

```sh
nim c whateverfile.nim
# *nix
./whateverfile
# Win
whateverfile.exe
```
