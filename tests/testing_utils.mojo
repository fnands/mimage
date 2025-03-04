from tensor import Tensor
from python import Python
from testing import assert_true


fn compare_to_numpy(mojo_tensor: Tensor, image_path: StringLiteral) raises:
    var PillowImage = Python.import_module("PIL.Image")
    var np = Python.import_module("numpy")
    var py_array = np.array(PillowImage.open(image_path))

    for rows in range(mojo_tensor.shape()[0]):
        for columns in range(mojo_tensor.shape()[1]):
            for channels in range(mojo_tensor.shape()[2]):
                print(mojo_tensor[rows, columns, channels])
                print(py_array[rows][columns][channels])
                # print(mojo_tensor[rows, columns, channels] == py_array[rows][columns][channels].__int__())
                print(mojo_tensor[rows, columns, channels].element_type)
                print(Python.type(py_array[rows][columns][channels]))
                print(py_array[rows][columns][channels].__as_int__())
                assert_true(
                    mojo_tensor[rows, columns, channels] == py_array[rows][columns][channels].__int__(),
                    "Pixel values do not match",
                )


#                     "Pixel values do not match, mojo: " + String(mojo_tensor[rows, columns, channels]) + " numpy: " + String(py_array[rows][columns][channels].__int__()),
