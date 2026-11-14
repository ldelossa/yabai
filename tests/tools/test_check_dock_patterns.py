import struct
import unittest

from check_dock_patterns import checked_slice, decode_adrp_add, find_matches, select_slice


class OfflineCheckerTests(unittest.TestCase):
    def test_ranges_do_not_cross_file_end(self):
        self.assertEqual(checked_slice(b"abcd", 2, 2), b"cd")
        for offset, size in ((2, 3), (-1, 1), (1, -1)):
            with self.assertRaises(ValueError):
                checked_slice(b"abcd", offset, size)

    def test_overlapping_aligned_matches_remain_ambiguous(self):
        self.assertEqual(find_matches(bytes(12), "00 00 00 00 00"), [0, 4])
        self.assertEqual(find_matches(b"\0\x12\x34\x56\x78", "12 34 56 78"), [])

    def test_scan_bounds_and_wildcards(self):
        data = b"\x12\x34\x56\x78"
        self.assertEqual(find_matches(data, "12 ?? ?8 78"), [0])
        self.assertEqual(find_matches(data[:3], "12 34 56 78"), [])
        for pattern in ("", "1", "GG 34"):
            with self.assertRaises(ValueError):
                find_matches(data, pattern)

    def test_slice_selection_cannot_cross_fat_entry_bounds(self):
        header = struct.pack(">II", 0xCAFEBABE, 1)
        entry = struct.pack(">IIIII", 0x100000C, 0x80000002, 28, 8, 0)
        self.assertEqual(select_slice(header + entry + b"12345678", "arm64e"), b"12345678")
        with self.assertRaises(ValueError):
            select_slice(header + entry + b"short", "arm64e")
        with self.assertRaises(ValueError):
            select_slice(header + entry + b"12345678", "arm64e.x1")

    def test_signed_adrp_and_register_validation(self):
        self.assertEqual(decode_adrp_add(struct.pack("<II", 0xF0001848, 0x913F4108), 0x10002FCB8), 0x10033AFD0)
        self.assertEqual(decode_adrp_add(struct.pack("<II", 0xF0FFFFE8, 0x91000108), 0x100020000), 0x10001F000)
        with self.assertRaises(ValueError):
            decode_adrp_add(struct.pack("<II", 0xF0FFFFE8, 0x91000129), 0x100020000)


if __name__ == "__main__":
    unittest.main()
