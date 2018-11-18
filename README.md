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
