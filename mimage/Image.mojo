from pathlib import Path
from tensor import Tensor


from mimage.PngImagePlugin import PNGImage


struct Image:
    """A struct representing an generic image."""

    var raw_image: PNGImage
    """The raw image object."""
    var width: Int
    """The width of the image."""
    var height: Int
    """The height of the image."""
    var channels: Int
    """The number of channels in the image."""

    fn __init__(inout self, image: PNGImage):
        """Initialize the Image struct.

        Args:
            image: The raw image object.
        """
        self.raw_image = image
        self.width = image.width
        self.height = image.height
        self.channels = image.channels

    fn to_tensor(self) raises -> Tensor[DType.uint8]:
        """Convert the image to a tensor.

        Returns:
            A tensor representing the image.

        Raises:
            Error: If the image cannot be converted to a tensor.
        """
        return self.raw_image.to_tensor()


# PNGImage opens these cases as well, should I just do one convert here?
# What if people want to directly call PNGImage?
fn open(image_path: StringLiteral) raises -> Image:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return Image(PNGImage(image_path))


fn open(image_path: String) raises -> Image:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return Image(PNGImage(image_path))


fn open(image_path: Path) raises -> Image:
    """Open an image file, returning an instance of the Image sctruct.

    Args:
        image_path: The path to the image file.

    Returns:
        An instance of the Image struct.
    """
    return Image(PNGImage(image_path))
