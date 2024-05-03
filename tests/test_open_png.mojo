from mimage import Image
from pathlib import Path
from tests import compare_to_numpy


def main():
    # Relative path from where?
    image = Image.open("tests/images/hopper.png")
    image = Image.open(String("tests/images/hopper.png"))
    image = Image.open(Path("tests/images/hopper.png"))

    hop_tensor = image.to_tensor()

    compare_to_numpy(hop_tensor, "tests/images/hopper.png")
