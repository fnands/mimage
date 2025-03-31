from tensor import Tensor, TensorSpec, TensorShape
from utils.index import Index
from testing import assert_true
from pathlib import Path

from mimage.utils.binary import (
    bytes_to_uint32_be,
    bytes_to_string,
    bytes_to_hex_string,
)
from mimage.utils.crc import CRC32
from mimage.utils.compression import uncompress
from mimage.utils.files import determine_file_type


fn _undo_trivial(current: Int16, left: Int16 = 0, above: Int16 = 0, above_left: Int16 = 0) -> Int16:
    return current


fn _undo_sub(current: Int16, left: Int16 = 0, above: Int16 = 0, above_left: Int16 = 0) -> Int16:
    return current + left


fn _undo_up(current: Int16, left: Int16 = 0, above: Int16 = 0, above_left: Int16 = 0) -> Int16:
    return current + above


fn _undo_average(current: Int16, left: Int16 = 0, above: Int16 = 0, above_left: Int16 = 0) -> Int16:
    return current + ((above + left) >> 1)  # Bitshift is equivalent to division by 2


fn _undo_paeth(current: Int16, left: Int16 = 0, above: Int16 = 0, above_left: Int16 = 0) -> Int16:
    var peath: Int16 = left + above - above_left
    var peath_a: Int16 = abs(peath - left)
    var peath_b: Int16 = abs(peath - above)
    var peath_c: Int16 = abs(peath - above_left)
    if (peath_a <= peath_b) and (peath_a <= peath_c):
        return current + left
    elif peath_b <= peath_c:
        return current + above
    else:
        return current + above_left


fn _undo_filter(
    filter_type: UInt8,
    current: UInt8,
    left: UInt8 = 0,
    above: UInt8 = 0,
    above_left: UInt8 = 0,
) raises -> UInt8:
    var current_int = current.cast[DType.int16]()
    var left_int = left.cast[DType.int16]()
    var above_int = above.cast[DType.int16]()
    var above_left_int = above_left.cast[DType.int16]()
    var result_int: Int16 = 0

    if filter_type == 0:
        result_int = _undo_trivial(current_int, left_int, above_int, above_left_int)
    elif filter_type == 1:
        result_int = _undo_sub(current_int, left_int, above_int, above_left_int)
    elif filter_type == 2:
        result_int = _undo_up(current_int, left_int, above_int, above_left_int)
    elif filter_type == 3:
        result_int = _undo_average(current_int, left_int, above_int, above_left_int)
    elif filter_type == 4:
        result_int = _undo_paeth(current_int, left_int, above_int, above_left_int)
    else:
        raise Error("Unknown filter type")
    return result_int.cast[DType.uint8]()


struct Chunk(Movable, Copyable):
    """A struct representing a PNG chunk."""

    var length: UInt32
    """The lengh of the chunk (in bytes)."""
    var type: String
    """The type of the chunk."""
    var data: List[UInt8]
    """The data contained in the chunk."""
    var crc: UInt32
    """The CRC32 checksum of the chunk."""
    var end: Int
    """The position in the data list where the chunk ends."""

    fn __init__(
        mut self,
        length: UInt32,
        chunk_type: String,
        data: List[UInt8],
        crc: UInt32,
        end: Int,
    ):
        """Initializes a new Chunk struct.

        Args:
            length: The length of the chunk.
            chunk_type: The type of the chunk.
            data: The data contained in the chunk.
            crc: The CRC32 checksum of the chunk.
            end: The position in the data list where the chunk ends.
        """
        self.length = length
        self.type = chunk_type
        self.data = data
        self.crc = crc
        self.end = end

    fn __moveinit__(mut self, owned existing: Chunk):
        """Move data of an existing Chunk into a new one.

        Args:
            existing: The existing Chunk.
        """
        self.length = existing.length
        self.type = existing.type
        self.data = existing.data
        self.crc = existing.crc
        self.end = existing.end

    fn __copyinit__(mut self, existing: Chunk):
        """Copy constructor for the Chunk struct.

        Args:
          existing: The existing struct to copy from.
        """
        self.length = existing.length
        self.type = existing.type
        self.data = existing.data
        self.crc = existing.crc
        self.end = existing.end


def parse_next_chunk(data: List[UInt8], read_head: Int) -> Chunk:
    """Parses the chunk starting at read head.

    Args:
        data: A list containing the raw data in the PNG file.
        read_head: The position in the data list to start reading the chunk.

    Returns:
        A Chunk struct containing the information contained in the chink starting at read head.
    """
    chunk_length = bytes_to_uint32_be(data[read_head : read_head + 4])[0]
    chunk_type = bytes_to_string(data[read_head + 4 : read_head + 8])
    start_data = Int(read_head + 8)
    end_data = Int(start_data + chunk_length)
    chunk_data = data[start_data:end_data]
    start_crc = Int(end_data)
    end_crc = Int(start_crc + 4)
    chunk_crc = bytes_to_uint32_be(data[start_crc:end_crc])[0]

    # Check CRC
    assert_true(
        CRC32(data[read_head + 4 : end_data]) == chunk_crc,
        "CRC32 does not match",
    )
    return Chunk(
        length=chunk_length,
        chunk_type=chunk_type,
        data=chunk_data,
        crc=chunk_crc,
        end=end_crc,
    )


struct PNGImage(Copyable, Movable):
    """A struct representing a PNG Image."""

    var image_path: Path
    """The path to the PNG image."""
    var raw_data: List[UInt8]
    """The raw bytes of the PNG image."""
    var width: Int
    """The width of the PNG image."""
    var height: Int
    """The height of the PNG image."""
    var channels: Int
    """The number of channels in the PNG image."""
    var bit_depth: Int
    """The bit depth of the PNG image."""
    var color_type: Int
    """The color type of the PNG image."""
    var compression_method: UInt8
    """The compression method of the PNG image."""
    var filter_method: UInt8
    """The filter method of the PNG image."""
    var interlaced: UInt8
    """Whether the PNG image is interlaced."""
    var data: List[UInt8]
    """The uncompressed data of the PNG image."""
    var data_type: DType
    """The data type of the PNG image. Either uint8 or uint16."""

    fn __init__(out self, file_name: Path) raises:
        """Initializes a new PNGImage struct.

        Args:
            file_name: The path to the PNG file.

        Raises:
            Error: If the file is not a PNG, is interlaced, or has an unsupported color type or bit depth.
        """
        self.image_path = file_name
        assert_true(
            self.image_path.exists(),
            "File '" + String(file_name) + "' does not exist",
        )

        with open(self.image_path, "r") as image_file:
            self.raw_data = image_file.read_bytes()

        assert_true(
            determine_file_type(self.raw_data) == "PNG",
            "File is not a PNG. Only PNGs are supported",
        )
        var read_head = 8

        var header_chunk = parse_next_chunk(self.raw_data, read_head)
        read_head = header_chunk.end

        self.width = Int(bytes_to_uint32_be(header_chunk.data[0:4])[0])
        self.height = Int(bytes_to_uint32_be(header_chunk.data[4:8])[0])
        self.bit_depth = Int(header_chunk.data[8].cast[DType.uint32]())
        self.color_type = Int(header_chunk.data[9])
        self.compression_method = header_chunk.data[10].cast[DType.uint8]()
        self.filter_method = header_chunk.data[11].cast[DType.uint8]()
        self.interlaced = header_chunk.data[12].cast[DType.uint8]()

        # There must be a better way to do this
        var color_type_dict = Dict[Int, Int]()
        color_type_dict[0] = 1
        color_type_dict[2] = 3
        color_type_dict[3] = 1
        color_type_dict[4] = 2
        color_type_dict[6] = 4

        self.channels = color_type_dict[self.color_type]

        if self.bit_depth == 8:
            self.data_type = DType.uint8
        elif self.bit_depth == 16:
            self.data_type = DType.uint16
        else:
            raise Error("Unknown bit depth")

        # Check color_type and bit_depth
        assert_true(self.color_type == 2 or self.color_type == 6, "Only RGB(A) images are supported")
        assert_true(self.bit_depth == 8, "Only 8-bit images are supported")

        # Check if the image is interlaced
        assert_true(self.interlaced == 0, "Interlaced images are not supported")
        # Chack compression method
        assert_true(self.compression_method == 0, "Compression method not supported")

        # Scan over chunks until end found
        var ended = False
        var data_found = False
        var uncompressd_data = List[UInt8]()
        while read_head < len(self.raw_data) and not ended:
            var chunk = parse_next_chunk(self.raw_data, read_head)
            read_head = chunk.end

            if chunk.type == "IDAT":
                uncompressd_data.extend(chunk.data)
                data_found = True
            elif chunk.type == "IEND":
                ended = True

        assert_true(ended, "IEND chunk not found")
        assert_true(data_found, "IDAT chunk not found")
        self.data = uncompress(uncompressd_data)

    # In case the filename is passed as a String
    fn __init__(out self, file_name: String) raises:
        """Initializes a new PNGImage struct.

        Args:
            file_name: The path to the PNG file.

        Raises:
            Error: If the file is not a PNG, is interlaced, or has an unsupported color type or bit depth.
        """
        return PNGImage(Path(file_name))

    # In case the filename is passed as a StringLiteral
    fn __init__(out self, file_name: StringLiteral) raises:
        """Initializes a new PNGImage struct.

        Args:
            file_name: The path to the PNG file.

        Raises:
            Error: If the file is not a PNG, is interlaced, or has an unsupported color type or bit depth.
        """
        return PNGImage(Path(file_name))

    fn __moveinit__(out self, owned existing: PNGImage):
        """Move data of an existing PNGImage into a new one.

        Args:
            existing: The existing PNGImage.
        """
        self.image_path = existing.image_path
        self.raw_data = existing.raw_data
        self.width = existing.width
        self.height = existing.height
        self.channels = existing.channels
        self.bit_depth = existing.bit_depth
        self.color_type = existing.color_type
        self.compression_method = existing.compression_method
        self.filter_method = existing.filter_method
        self.interlaced = existing.interlaced
        self.data = existing.data
        self.data_type = existing.data_type

    fn __copyinit__(out self, existing: PNGImage):
        """Copy constructor for the PNGImage struct.

        Args:
          existing: The existing struct to copy from.
        """
        self.image_path = existing.image_path
        self.raw_data = existing.raw_data
        self.width = existing.width
        self.height = existing.height
        self.channels = existing.channels
        self.bit_depth = existing.bit_depth
        self.color_type = existing.color_type
        self.compression_method = existing.compression_method
        self.filter_method = existing.filter_method
        self.interlaced = existing.interlaced
        self.data = existing.data
        self.data_type = existing.data_type

    fn to_tensor(self) raises -> Tensor[DType.uint8]:
        """Converts the PNG image to a Tensor.

        Returns:
            A Tensor containing the image data.
        """
        var spec = TensorSpec(DType.uint8, self.height, self.width, self.channels)
        var tensor_image = Tensor[DType.uint8](spec)

        var pixel_size: Int = self.channels * (self.bit_depth // 8)

        # Initialize the previous scanline to 0
        var previous_result = List[UInt8](0 * self.width)

        for line in range(self.height):
            var offset = 1 + 1 * line + line * self.width * pixel_size
            var left: UInt8 = 0
            var above_left: UInt8 = 0

            var result = List[UInt8](capacity=self.width * pixel_size)
            var scanline = self.data[offset : offset + self.width * pixel_size]

            var filter_type = self.data[offset - 1]

            for i in range(len(scanline)):
                if i >= pixel_size:
                    left = result[i - pixel_size]
                    above_left = previous_result[i - pixel_size]

                result.append(
                    _undo_filter(
                        filter_type,
                        self.data[i + offset],
                        left,
                        previous_result[i],
                        above_left,
                    )
                )

            previous_result = result
            for i in range(self.width):
                for j in range(self.channels):
                    tensor_image[Index(line, i, j)] = result[i * self.channels + j]

        return tensor_image
