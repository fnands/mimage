from pathlib import Path

from mimage.PngImagePlugin import PNGImage


# PNGImage opens these cases as well, should I just do one convert here?
# What if people want to directly call PNGImage?
fn open(image_path: StringLiteral) raises -> PNGImage:
    return PNGImage(image_path)


fn open(image_path: String) raises -> PNGImage:
    return PNGImage(image_path)


fn open(image_path: Path) raises -> PNGImage:
    return PNGImage(image_path)
