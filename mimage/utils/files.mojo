from mimage.utils.binary import bytes_to_hex_string


fn determine_file_type(data: List[Int8]) -> String:
    # Is there a better way? Probably
    if bytes_to_hex_string(data[0:8]) == String(
        "0x890x500x4e0x470xd0xa0x1a0xa"
    ):
        return "PNG"
    else:
        return "Unknown"
