from sys import ffi
from memory import memset_zero


alias Bytef = Scalar[DType.uint8]
alias uLong = UInt64
alias zlib_type = fn (
    _out: UnsafePointer[Bytef],
    _out_len: UnsafePointer[UInt64],
    _in: UnsafePointer[Bytef],
    _in_len: uLong,
) -> Int


fn _log_zlib_result(Z_RES: Int, compressing: Bool = True) raises -> NoneType:
    var prefix: String = ""
    if not compressing:
        prefix = "un"

    if Z_RES == 0:
        print("OK " + prefix.upper() + "COMPRESSING: Everything " + prefix + "compressed fine")
    elif Z_RES == -4:
        raise Error("ERROR " + prefix.upper() + "COMPRESSING: Not enought memory")
    elif Z_RES == -5:
        raise Error("ERROR " + prefix.upper() + "COMPRESSING: Buffer have not enough memory")
    else:
        raise Error("ERROR " + prefix.upper() + "COMPRESSING: Unhandled exception")


fn uncompress(data: List[UInt8], quiet: Bool = True) raises -> List[UInt8]:
    """Uncompresses a zlib compressed byte List.

    Args:
        data: The zlib compressed byte List.
        quiet: Whether to print the result of the zlib operation. Defaults to True.

    Returns:
        The uncompressed byte List.

    Raises:
        Error: If the zlib operation fails.
    """
    var data_memory_amount: Int = len(data) * 10
    var handle = ffi.DLHandle("")
    var zlib_uncompress = handle.get_function[zlib_type]("uncompress")

    var uncompressed = UnsafePointer[Bytef].alloc(data_memory_amount)
    var compressed = UnsafePointer[Bytef].alloc(len(data))
    var uncompressed_len = UnsafePointer[uLong].alloc(1)
    memset_zero(uncompressed, data_memory_amount)
    memset_zero(uncompressed_len, 1)
    uncompressed_len[0] = data_memory_amount
    for i in range(len(data)):
        compressed.store(i, data[i])

    var Z_RES = zlib_uncompress(
        uncompressed,
        uncompressed_len,
        compressed,
        len(data),
    )

    if not quiet:
        _log_zlib_result(Z_RES, compressing=False)
        print("Uncompressed length: " + str(uncompressed_len[0]))
    # Can probably do something more efficient here with pointers, but eh.
    var res = List[UInt8]()
    for i in range(uncompressed_len[0]):
        res.append(uncompressed[i])
    return res
