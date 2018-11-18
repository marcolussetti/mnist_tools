# MNIST Tools

```sh
nimble install https://github.com/marcolussetti/mnist_tools
```

If files are in the local directory, just use mnistLoadDefaults(). Else refer to mnistLoad(imageFilePath: string, labelFilePath: string). Can load .gz files.

Returns a sequence of tuples:
```nim
type
    MnistImage = tuple[label: int, image: seq[int]]
```

Provides a very coarse ascii print of the image as such:
```nim
import mnist_tools
# Will automatically download in local directory or other provided path
let mnistTraining = mnistTrainingData()
let mnistTest = mnistTestData()

echo mnistTraining[7].image.mnistCoarseAsciiImage # Should print a "3"
```
