from bit import byte_swap, bit_reverse
from testing import assert_true
from algorithm import vectorize
from sys.info import simdwidthof

# a recommended batch size for your machine
alias simd_width = simdwidthof[DType.uint32]()


fn bytes_to_string(list: List[UInt8]) -> String:
    """Converts a list of bytes to a string.

    Args:
        list: The List of bytes.

    Returns:
        The String representation of the bytes.
    """
    var word = String("")
    for letter in list:
        word += chr(int(letter[].cast[DType.uint8]()))

    return word


fn bytes_to_hex_string(list: List[UInt8]) -> String:
    """Converts a list of bytes to a hex string.

    Args:
        list: The List of bytes.

    Returns:
        The hex String representation of the bytes.
    """
    var word = String("")
    for letter in list:
        word += hex(int(letter[].cast[DType.uint8]()))

    return word


fn bytes_to_uint32_be(owned list: List[UInt8]) raises -> List[UInt32]:
    """Converts a list of bytes into a list of UInt32s.

    Args:
        list: The List of bytes.

    Returns:
        Input data translated to a List of UInt32.

    Raises:
        ValueError: If the length of the input list is not a multiple of 4.
    """
    assert_true(
        len(list) % 4 == 0,
        "List[UInt8] length must be a multiple of 4 to convert to List[UInt32]",
    )
    var result_length = len(list) // 4

    # get the data pointer with ownership.
    # This avoids copying and makes sure only one List owns a pointer to the underlying address.
    var ptr_to_uint8 = list.steal_data()
    var ptr_to_uint32 = ptr_to_uint8.bitcast[UInt32]()
    var dtype_ptr = UnsafePointer[Scalar[DType.uint32]](ptr_to_uint32.address)

    # vectorize byte_swap over UnsafePointer
    @parameter
    fn _byte_swap[_width: Int](i: Int):
        # call byte_swap on a batch of UInt32 values
        var bit_swapped = byte_swap(dtype_ptr.load[width=_width](i))
        # We are updating in place and both ptr_to_uint32 and dtype_ptr share the addresses
        dtype_ptr.store[width=_width](i, bit_swapped)

    # swap the bytes in each UInt32 to convert from big-endian to little-endian
    vectorize[_byte_swap, simd_width](result_length)

    return List[UInt32](unsafe_pointer=ptr_to_uint32, size=result_length, capacity=result_length)
