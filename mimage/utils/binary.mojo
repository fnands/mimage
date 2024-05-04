from math.bit import bswap, bitreverse
from testing import assert_true
from algorithm import vectorize
from sys.info import simdwidthof


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


# a recommended batch size for your machine
alias simd_width = simdwidthof[DType.uint32]()


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
    var dtype_ptr = DTypePointer[DType.uint32](
        Pointer[UInt32](ptr_to_uint32.address)
    )

    # vectorize bswap over DTypePointer
    @parameter
    fn _bswap[_width: Int](i: Int):
        # call bswap on a batch of UInt32 values
        var bit_swapped = bswap(dtype_ptr.load[width=_width](i))
        # We are updating in place and both ptr_to_uint32 and dtype_ptr share the addresses
        dtype_ptr.store[width=_width](i, bit_swapped)

    # swap the bytes in each UInt32 to convert from big-endian to little-endian
    vectorize[_bswap, simd_width](result_length)

    var result = List[UInt32]()
    result.data = ptr_to_uint32
    result.capacity = result_length
    result.size = result_length

    return result
