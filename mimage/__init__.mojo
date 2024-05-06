from tensor import Tensor
from pathlib import Path
from mimage.PngImagePlugin import PNGImage


# PNGImage opens these cases as well, should I just do one convert here?
# What if people want to directly call PNGImage?
fn imread(image_path: StringLiteral) raises -> Tensor[DType.uint8]:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return PNGImage(image_path).to_tensor()


fn imread(image_path: String) raises -> Tensor[DType.uint8]:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return PNGImage(image_path).to_tensor()


fn imread(image_path: Path) raises -> Tensor[DType.uint8]:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return PNGImage(image_path).to_tensor()
