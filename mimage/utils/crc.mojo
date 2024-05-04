from math.bit import bitreverse


fn CRC32(
    data: List[SIMD[DType.int8, 1]],
    value: SIMD[DType.uint32, 1] = 0xFFFFFFFF,
) -> SIMD[DType.uint32, 1]:
    """Calculate the CRC32 value for a given list of bytes.

    Args:
        data: The list of bytes for chich to calulate the CRC32 value.
        value: The initial value of the CRC32 calculation.

    Returns:
        The CRC32 value for the given list of bytes.
    """
    var crc32 = value
    for byte in data:
        crc32 = (bitreverse(byte[]).cast[DType.uint32]() << 24) ^ crc32
        for i in range(8):
            if crc32 & 0x80000000 != 0:
                crc32 = (crc32 << 1) ^ 0x04C11DB7
            else:
                crc32 = crc32 << 1

    return bitreverse(crc32 ^ 0xFFFFFFFF)
