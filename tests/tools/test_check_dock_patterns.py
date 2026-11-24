import copy
import struct
import unittest
from unittest.mock import patch

from check_dock_patterns import checked_slice, check_core, decode_adrp_add, find_matches, select_slice, source_profiles


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

    def profile_report(self, profile):
        patterns = {name: dict(count=1, hits=[dict(relative_vmaddr=hex(offset), function_start=True)])
                    for name, offset in profile['offsets'].items()}
        patterns['dock_spaces']['hits'][0].update(pointer_slot=hex(profile['pointer_slot']),
                                                 pointer_segment='__DATA', pointer_writable=True)
        return dict(uuid=profile['uuid'], build=profile['build'], arch='arm64e',
                    subtype=hex(profile['subtype']), patterns=patterns)

    def test_both_exact_profiles_and_optional_build(self):
        profiles = source_profiles()
        self.assertEqual({p['build'] for p in profiles}, {'26C5035r', '26C5047e'})
        self.assertEqual(len(profiles), 2)
        self.assertNotEqual(profiles[0]['pointer_slot'], profiles[1]['pointer_slot'])
        for profile in profiles:
            report = self.profile_report(profile)
            self.assertTrue(check_core(report))
            del report['build']  # Offline binary UUID check, not a host-build assertion.
            self.assertTrue(check_core(report))

    def test_cross_combined_and_unknown_identities_fail_closed(self):
        profiles = source_profiles()
        for i, profile in enumerate(profiles):
            good = self.profile_report(profile)
            for field, value in [('uuid', profiles[1-i]['uuid']), ('build', profiles[1-i]['build']),
                                 ('build', 'future'), ('uuid', '00000000-0000-0000-0000-000000000000'),
                                 ('subtype', '0x8000000c'), ('subtype', '0x2'), ('arch', 'arm64e.x1')]:
                report = copy.deepcopy(good)
                report[field] = value
                self.assertFalse(check_core(report), (profile['build'], field, value))
        with patch('check_dock_patterns.source_profiles', return_value=[profiles[0], profiles[0]]):
            self.assertFalse(check_core(self.profile_report(profiles[0])))

    def test_offsets_slot_boundaries_and_uniqueness_remain_strict(self):
        for profile in source_profiles():
            good = self.profile_report(profile)
            for name in profile['offsets']:
                report = copy.deepcopy(good)
                report['patterns'][name]['hits'][0]['relative_vmaddr'] = hex(profile['offsets'][name] + 4)
                self.assertFalse(check_core(report))
                report = copy.deepcopy(good)
                report['patterns'][name]['count'] = 2
                report['patterns'][name]['hits'] *= 2
                self.assertFalse(check_core(report))
            for key, value in [('pointer_slot', '0x0'), ('pointer_writable', False), ('pointer_segment', '__TEXT')]:
                report = copy.deepcopy(good)
                report['patterns']['dock_spaces']['hits'][0][key] = value
                self.assertFalse(check_core(report))
            for name in ('add_space', 'remove_space'):
                report = copy.deepcopy(good)
                report['patterns'][name]['hits'][0]['function_start'] = False
                self.assertFalse(check_core(report))
            report = copy.deepcopy(good)
            report['patterns']['add_space']['hits'] = []
            self.assertFalse(check_core(report))

    def test_signed_adrp_and_register_validation(self):
        self.assertEqual(decode_adrp_add(struct.pack("<II", 0xF0001848, 0x913F4108), 0x10002FCB8), 0x10033AFD0)
        self.assertEqual(decode_adrp_add(struct.pack("<II", 0xF0FFFFE8, 0x91000108), 0x100020000), 0x10001F000)
        with self.assertRaises(ValueError):
            decode_adrp_add(struct.pack("<II", 0xF0FFFFE8, 0x91000129), 0x100020000)


if __name__ == "__main__":
    unittest.main()
