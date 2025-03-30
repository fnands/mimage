from bit import bit_reverse


fn fill_table_n_byte[n: Int]() -> List[UInt32]:
    """Fill a table with pre-computed values for the CRC32 calculation.

    Parameters:
        n: The size in bytes of the data word size. Must be a multiple of 4.

    Returns:
        The table with pre-computed values for the CRC32 calculation.
    """
    var table = List[UInt32](capacity=256 * n)

    for i in range(256 * n):
        if i < 256:
            var key = UInt8(i)
            var crc32 = key.cast[DType.uint32]()
            for _ in range(8):
                if crc32 & 1 != 0:
                    crc32 = (crc32 >> 1) ^ 0xEDB88320
                else:
                    crc32 = crc32 >> 1

            table[i] = crc32
        else:
            var crc32 = table[i - 256]
            var index = Int(crc32.cast[DType.uint8]())
            table[i] = (crc32 >> 8) ^ table[index]

    return table


fn CRC32_table_n_byte_compact[word_size: Int](data: List[UInt8], table: List[UInt32]) -> UInt32:
    """Calculate the CRC32 value for a given list of bytes using a pre-computed table.

    Parameters:
        word_size: The size in bytes of the data word size. Must be a multiple of 4.

    Args:
        data: The list of bytes for chich to calulate the CRC32 value.
        table: The table to use for the CRC32 calculation. This must correspond to the word_size.

    Returns:
        The CRC32 value for the given list of bytes.
    """
    var crc32: UInt32 = 0xFFFFFFFF

    alias step_size = 4  # Always smashing 4 bytes into an UInt32
    alias units = word_size // step_size

    var length = len(data) // word_size
    var extra = len(data) % word_size

    var n = 0

    for i in range(start=0, end=length * word_size, step=word_size):

        @parameter
        for j in range(units):
            var vals = (
                (data[i + j * step_size + 3].cast[DType.uint32]() << 24)
                | (data[i + j * step_size + 2].cast[DType.uint32]() << 16)
                | (data[i + j * step_size + 1].cast[DType.uint32]() << 8)
                | (data[i + j * step_size + 0].cast[DType.uint32]() << 0)
            )

            if j == 0:
                vals = vals ^ crc32
                crc32 = 0

            n = word_size - j * step_size
            crc32 = (
                table[(n - 4) * 256 + Int((vals >> 24).cast[DType.uint8]())]
                ^ table[(n - 3) * 256 + Int((vals >> 16).cast[DType.uint8]())]
                ^ table[(n - 2) * 256 + Int((vals >> 8).cast[DType.uint8]())]
                ^ table[(n - 1) * 256 + Int((vals >> 0).cast[DType.uint8]())]
            ) ^ crc32

    for i in range(word_size * length, word_size * length + extra):
        var index = (crc32 ^ data[i].cast[DType.uint32]()) & 0xFF
        crc32 = table[Int(index)] ^ (crc32 >> 8)

    return crc32 ^ 0xFFFFFFFF


fn CRC32(
    data: List[SIMD[DType.uint8, 1]],
    value: SIMD[DType.uint32, 1] = 0xFFFFFFFF,
) -> SIMD[DType.uint32, 1]:
    """Calculate the CRC32 value for a given list of bytes.

    Args:
        data: The list of bytes for chich to calulate the CRC32 value.
        value: The initial value of the CRC32 calculation.

    Returns:
        The CRC32 value for the given list of bytes.
    """
    alias N = 32

    alias table = fill_table_n_byte[N]()

    return CRC32_table_n_byte_compact[N](data, table)
