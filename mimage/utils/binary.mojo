from math.bit import bswap, bitreverse
from testing import assert_true


fn bytes_to_string(list: List[Int8]) -> String:
    var word = String("")
    for letter in list:
        word += chr(int(letter[].cast[DType.uint8]()))

    return word


fn bytes_to_hex_string(list: List[Int8]) -> String:
    var word = String("")
    for letter in list:
        word += hex(int(letter[].cast[DType.uint8]()))

    return word


fn bytes_to_uint32_be(owned list: List[Int8]) raises -> List[UInt32]:
    assert_true(
        len(list) % 4 == 0,
        "List[Int8] length must be a multiple of 4 to convert to List[Int32]",
    )
    var result_length = len(list) // 4

    # get the data pointer with ownership.
    # This avoids copying and makes sure only one List owns a pointer to the underlying address.
    var ptr_to_int8 = list.steal_data()
    var ptr_to_uint32 = ptr_to_int8.bitcast[UInt32]()

    var result = List[UInt32]()
    result.data = ptr_to_uint32
    result.capacity = result_length
    result.size = result_length

    # swap the bytes in each UInt32 to convert from big-endian to little-endian
    for i in range(result_length):
        result[i] = bswap(result[i])

    return result
