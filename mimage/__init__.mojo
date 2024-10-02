from tensor import Tensor
from pathlib import Path
from mimage.PngImagePlugin import PNGImage
from collections import Dict


# PNGImage opens these cases as well, should I just do one convert here?
# What if people want to directly call PNGImage?
fn imread(image_path: StringLiteral) raises -> Tensor[DType.uint8]:
    """Open an image file, returning a Tensor with the image content.

    Args:
        image_path: The path to the image file.

    Returns:
        A tensor with the image data.
    """
    return PNGImage(image_path).to_tensor()


fn imread(image_path: String) raises -> Tensor[DType.uint8]:
    """Open an image file, returning a Tensor with the image content.

    Args:
        image_path: The path to the image file.

    Returns:
        A tensor with the image data.
    """
    return PNGImage(image_path).to_tensor()


fn imread(image_path: Path) raises -> Tensor[DType.uint8]:
    """Open an image file, returning a Tensor with the image content.

    Args:
        image_path: The path to the image file.

    Returns:
        A tensor with the image data.
    """
    return PNGImage(image_path).to_tensor()
