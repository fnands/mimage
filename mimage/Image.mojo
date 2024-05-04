from pathlib import Path

from mimage.PngImagePlugin import PNGImage


# PNGImage opens these cases as well, should I just do one convert here?
# What if people want to directly call PNGImage?
fn open(image_path: StringLiteral) raises -> PNGImage:
    """Open an image file, returning an instance of the PNGImage sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the PNGImage struct.
    """
    return PNGImage(image_path)


fn open(image_path: String) raises -> PNGImage:
    """Open an image file, returning an instance of the PNGImage sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the PNGImage struct.
    """
    return PNGImage(image_path)


fn open(image_path: Path) raises -> PNGImage:
    """Open an image file, returning an instance of the PNGImage sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the PNGImage struct.
    """
    return PNGImage(image_path)
